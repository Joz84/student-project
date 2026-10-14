# -*- coding: utf-8 -*-
# Algorithme d'affectation élèves→projets avec groupes de 3 ou 4
# Objectif principal : maximiser la somme des notes
# Objectif secondaire (si K non fixé) : minimiser le nombre de groupes (→ max de groupes de 4)
#
# Usage minimal : voir le bloc __main__ en bas.

from ortools.linear_solver import pywraplp
import argparse
import ast
import glob
import json
import math
import os
import sys
from typing import Dict, Iterable, Tuple, List, Optional, Set


# Un projet accueillant plusieurs groupes est dupliqué en autant de créneaux.
# Le libellé d'un créneau reste égal au nom du projet quand il n'y en a qu'un,
# ce qui garde les sorties identiques aux versions précédentes.
SLOT_SEP = " || groupe "

# Taille de groupe visée. Au-delà, chaque élève supplémentaire est pénalisé.
TARGET_SIZE = 4

# Plafond de la phase 2 (minimiser le nombre de groupes). Le score, lui, est
# décidé en phase 1 : c'est elle qui mérite le budget de temps.
# Une catégorie à groupes homogènes comptant exactement ce nombre d'élèves forme
# un groupe unique de cette taille : 5 ne se découpe ni en 3+2 ni en 4+1.
EXCEPTION_SIZE = 5


def slot_label(project: str, index: int, n_slots: int) -> str:
    return project if n_slots == 1 else f"{project}{SLOT_SEP}{index + 1}"


def _exigences_par_sujet(min_per_subject, projects, subject_of) -> Dict[str, int]:
    """
    Combien de projets au minimum doivent être retenus dans chaque catégorie.

    Un entier vaut pour toutes les catégories présentes ; un dict permet de
    doser catégorie par catégorie. Un projet sans catégorie n'est jamais
    comptabilisé : il ne peut donc pas satisfaire une exigence.
    """
    if not min_per_subject:
        return {}
    presents = {subject_of.get(p) for p in projects if subject_of.get(p)}
    if isinstance(min_per_subject, dict):
        return {str(k): int(v) for k, v in min_per_subject.items() if int(v) > 0}
    return {s: int(min_per_subject) for s in sorted(presents)}


def _check_sujets(exigences, projects, subject_of, students, min_size, k_projects):
    """
    Trois façons d'exiger l'impossible, dites avant de lancer le solveur :
    une catégorie trop peu fournie, un total d'exigences qui dépasse le nombre
    de groupes formables, et un total qui dépasse le nombre de groupes imposé.
    """
    if not exigences:
        return
    disponibles = {}
    for sujet in exigences:
        disponibles[sujet] = sum(1 for p in projects if subject_of.get(p) == sujet)
    manquants = {s: (n, disponibles[s]) for s, n in exigences.items() if disponibles[s] < n}
    if manquants:
        details = "; ".join(f"{s} : {d} projet(s) pour {n} exigé(s)"
                            for s, (n, d) in sorted(manquants.items()))
        raise ValueError(
            "Impossible d'ouvrir autant de projets par catégorie que demandé.\n"
            f"Détail  : {details}.\n"
            "Ajoutez des projets dans ces catégories, ou abaissez l'exigence."
        )

    total = sum(exigences.values())
    groupes_max = len(students) // min_size
    if total > groupes_max:
        raise ValueError(
            f"Les exigences par catégorie imposent au moins {total} groupes, "
            f"or {len(students)} élèves par groupes de {min_size} au minimum "
            f"n'en forment que {groupes_max}.\n"
            "Abaissez l'exigence, ou réduisez la taille minimale des groupes."
        )
    if k_projects is not None and total > k_projects:
        raise ValueError(
            f"Les exigences par catégorie imposent au moins {total} groupes, "
            f"or le nombre de groupes est fixé à {k_projects}."
        )


def project_of_slot(label: str) -> str:
    """Retrouve le projet derrière un libellé de créneau."""
    return label.split(SLOT_SEP, 1)[0]


def _coerce_scores(raw: dict) -> Dict[Tuple[str, str], float]:
    scores = {}
    for key, value in raw.items():
        if isinstance(key, tuple):
            scores[key] = value
        else:
            scores[tuple(ast.literal_eval(key))] = value
    return scores


def _parse_payload(payload):
    """
    Accepte deux formats.

    1. Format historique — le dict des notes seul :
           {'["élève", "projet"]': note, ...}
       Chaque projet accueille alors exactement un groupe et aucune contrainte
       de composition ne s'applique : comportement identique aux versions
       précédentes.

    2. Format complet, produit par `Batch#solver_payload` côté Rails :
           {
             "scores":       {'["élève", "projet"]': note, ...},
             "projects":     {"projet": {"max_booking": 4}, ...},
             "students":     {"élève": {"speciality": "peip"}, ...},
             "specialities": {"peip": {"exclusive_groups": true}, ...}
           }
       - max_booking      : nombre d'équipes que le projet peut accueillir.
       - subject          : catégorie du projet (« clustering »…), facultative.
                            Sert à exiger un minimum de projets ouverts par
                            catégorie, cf. `min_per_subject`.
       - exclusive_groups : les élèves de cette spécialité ne peuvent être
                            groupés qu'entre eux (les PEIP).
    """
    data = payload
    if isinstance(data, str):
        data = json.loads(data)
    # `Batch#scores.to_json` peut arriver encodé une seconde fois (cf. scores.json)
    if isinstance(data, str):
        data = json.loads(data)

    if isinstance(data, dict) and isinstance(data.get("scores"), dict):
        return (
            _coerce_scores(data["scores"]),
            data.get("projects") or {},
            data.get("students") or {},
            data.get("specialities") or {},
        )
    return _coerce_scores(data), {}, {}, {}


def _check_feasibility(students, projects, scores, n_slots,
                       min_size, max_size, k_projects,
                       speciality_of, exclusive, sans_pref=frozenset(), min_choosers=0):
    """Diagnostics lisibles, avant de laisser le solveur répondre « infaisable »."""
    N = len(students)
    total_slots = sum(n_slots[p] for p in projects)

    K_min = math.ceil(N / max_size)
    K_max = math.floor(N / min_size)
    if k_projects is None:
        if K_min > K_max:
            raise ValueError(
                f"Impossible de former uniquement des groupes de {min_size}..{max_size} "
                f"avec N={N} élèves (aucun K tel que {min_size}K ≤ {N} ≤ {max_size}K)."
            )
    else:
        if not (min_size * k_projects <= N <= max_size * k_projects):
            raise ValueError(
                f"K={k_projects} incompatible avec N={N} et tailles [{min_size},{max_size}]. "
                f"Il faut {K_min} ≤ K ≤ {K_max}."
            )
        if k_projects > total_slots:
            raise ValueError(
                f"K={k_projects} groupes demandés mais les projets n'offrent que "
                f"{total_slots} créneaux (somme des max_booking)."
            )

    if K_min > total_slots:
        raise ValueError(
            f"Capacité insuffisante : {N} élèves nécessitent au moins {K_min} groupes, "
            f"or les projets n'offrent que {total_slots} créneaux (somme des max_booking). "
            f"Augmentez max_booking."
        )

    # Capacité par bassin d'élèves partageant exactement les mêmes projets autorisés.
    # C'est ce qui attrape une filière à projet unique dont le max_booking est trop bas.
    pools: Dict[frozenset, List[str]] = {}
    for e in students:
        allowed = frozenset(p for p in projects if (e, p) in scores)
        pools.setdefault(allowed, []).append(e)
    for allowed, members in pools.items():
        seats = sum(n_slots[p] for p in allowed)
        if len(members) > seats * max_size:
            noms = ", ".join(sorted(allowed))
            raise ValueError(
                f"Capacité insuffisante : {len(members)} élèves n'ont accès qu'à [{noms}], "
                f"soit {seats * max_size} places au maximum ({seats} créneaux × {max_size}). "
                f"Augmentez max_booking sur ces projets."
            )

    if min_choosers > 0:
        n_choix = sum(1 for e in students if speciality_of.get(e) not in sans_pref)
        g_max = n_choix // min_choosers
        g_min = math.ceil(len(students) / max_size)
        if g_min > g_max:
            print(
                f"Note    : {min_choosers} élève(s) ayant classé par groupe est hors d'atteinte.\n"
                f"          {len(students)} élèves demandent au moins {g_min} groupes (taille max "
                f"{max_size}), or {n_choix} ont classé, ce qui n'en couvre que {g_max}.\n"
                f"          Le solveur s'en approchera au mieux."
            )

    # Une catégorie à groupes homogènes doit pouvoir se partitionner seule.
    # Cas particulier accepté : exactement 5, qui forme un unique groupe de 5.
    for g in exclusive:
        n = sum(1 for e in students if speciality_of.get(e) == g)
        if n == 0 or n == EXCEPTION_SIZE:
            continue
        if math.ceil(n / max_size) > math.floor(n / min_size):
            raise ValueError(
                f"La catégorie '{g}' impose des groupes homogènes mais compte {n} élève(s), "
                f"ce qui ne se partitionne pas en groupes de {min_size} à {max_size} "
                f"(seul {EXCEPTION_SIZE} est toléré en plus, sous forme d'un groupe unique)."
            )


def solve_assignment(
    scores_json,
    students: Optional[Iterable[str]] = None,
    projects: Optional[Iterable[str]] = None,
    min_size: int = 3,
    max_size: int = 4,
    k_projects: Optional[int] = None,
    lexicographic: bool = True,
    time_limit_s: float = 60,
    duplicate_penalty: Optional[float] = None,
    min_choosers: int = 0,
    min_per_subject=None,
    return_status: bool = False,
):
    """
    Résout l'affectation avec contraintes de taille de groupe ∈ [min_size, max_size].
    - scores_json : voir `_parse_payload` pour les deux formats acceptés
    - students, projects : déduits des notes si non fournis
    - min_size, max_size : tailles min et max par groupe
    - k_projects : si None → le solveur choisit le nombre de groupes ; sinon l'impose
    - lexicographic :
        * True  → 2 phases : (1) max score, (2) à score optimal, min #groupes
        * False → une seule phase (max score)
    - time_limit_s : temps maximal par phase. Phase 1 : le moins de groupes
      possible, donc le plus de groupes de 4 — c'est la règle prioritaire.
      Phase 2 : à ce nombre de groupes, le meilleur respect des vœux, en préférant
      des projets différents. Passé le délai, on garde la meilleure solution
      trouvée, qui reste valide.
    - duplicate_penalty : coût d'ouvrir un deuxième groupe sur un projet déjà pris.
      Par défaut il dépasse la somme de tous les scores, ce qui en fait une règle
      et non une préférence : un doublon n'est ouvert que s'il est structurellement
      inévitable. Abaissez-le pour autoriser un doublon qui améliore les vœux.
    - lexicographic : conservé pour compatibilité, sans effet — la résolution est
      toujours en deux temps (nombre de groupes, puis vœux).
    - min_choosers : nombre minimal d'élèves ayant exprimé des vœux par groupe. Les
      autres — ceux marqués no_preference dans les spécialités — viennent compléter
      les groupes sans jamais les composer à eux seuls.
    - min_per_subject : nombre minimal de projets retenus dans chaque catégorie
      (le `subject` des projets). Un entier s'applique à toutes les catégories
      présentes, un dict les dose une à une. Contrainte dure, et non préférence :
      un modèle qui ne peut la tenir est déclaré infaisable avant résolution.
    - return_status : renvoie un 5e élément décrivant le déroulé de la résolution.

    Retourne:
      selected        : set[str]                 (libellés des créneaux ouverts)
      assignment      : dict[str, list[str]]     (créneau -> élèves)
      objective_value : float                    (somme des notes)
      scores          : dict[(élève, projet), note]
    Lève ValueError si infaisable.
    """
    scores, projects_meta, students_meta, specialities_meta = _parse_payload(scores_json)

    # --- Déductions automatiques
    if students is None:
        students = sorted({e for (e, _) in scores.keys()})
    else:
        students = list(students)
    if projects is None:
        projects = sorted({p for (_, p) in scores.keys()})
    else:
        projects = list(projects)

    N = len(students)
    if N == 0:
        raise ValueError("Aucun élève fourni.")

    # --- Vérif: chaque élève a au moins un projet autorisé
    for e in students:
        if not any((e, p) in scores for p in projects):
            raise ValueError(f"Aucun projet autorisé/valué pour l'élève {e}")

    # --- Créneaux : un projet peut porter plusieurs groupes (max_booking)
    n_slots: Dict[str, int] = {}
    for p in projects:
        raw = (projects_meta.get(p) or {}).get("max_booking")
        n_slots[p] = max(1, int(raw)) if raw else 1
    slots = [(p, k) for p in projects for k in range(n_slots[p])]
    labels = {(p, k): slot_label(p, k, n_slots[p]) for (p, k) in slots}

    # --- Spécialités à groupes homogènes (les PEIP)
    speciality_of = {e: (students_meta.get(e) or {}).get("speciality") for e in students}
    exclusive = [
        g for g, meta in specialities_meta.items()
        if (meta or {}).get("exclusive_groups")
        and any(speciality_of.get(e) == g for e in students)
    ]
    sans_pref = {g for g, meta in specialities_meta.items() if (meta or {}).get("no_preference")}
    choisisseurs = [e for e in students if speciality_of.get(e) not in sans_pref]

    subject_of = {p: (projects_meta.get(p) or {}).get("subject") for p in projects}
    exigences_sujets = _exigences_par_sujet(min_per_subject, projects, subject_of)

    _check_feasibility(students, projects, scores, n_slots,
                       min_size, max_size, k_projects, speciality_of, exclusive,
                       sans_pref, min_choosers)
    _check_sujets(exigences_sujets, projects, subject_of, students, min_size, k_projects)

    # --- Construction du solveur
    solver = pywraplp.Solver.CreateSolver("CBC_MIXED_INTEGER_PROGRAMMING")
    if solver is None:
        raise RuntimeError("Impossible d'initialiser le solveur OR-Tools.")

    # --- Variables
    # x[e,s] = 1 si l'élève e est affecté au créneau s (seulement pour paires autorisées)
    x = {}
    for e in students:
        for s in slots:
            if (e, s[0]) in scores:
                x[(e, s)] = solver.BoolVar(f"x_{e}_{s[0]}_{s[1]}")

    # y[s] = 1 si le créneau s est ouvert (c'est un groupe)
    y = {s: solver.BoolVar(f"y_{s[0]}_{s[1]}") for s in slots}

    # z[g][s] = 1 si le créneau s est réservé à la catégorie exclusive g
    tailles_exclusives = {g: sum(1 for e in students if speciality_of.get(e) == g)
                          for g in exclusive}
    z = {g: {s: solver.BoolVar(f"z_{g}_{s[0]}_{s[1]}") for s in slots} for g in exclusive}

    # doublons : tout créneau au-delà du premier d'un projet
    doublons = [y[(p, k)] for p in projects for k in range(1, n_slots[p])]

    # dépassement de la taille cible : un groupe de 5 coûte 1, un de 6 coûte 2.
    # Sans ça, à nombre de groupes figé, rien ne pousse vers des groupes de 4 :
    # le solveur produit indifféremment 12x4+2x5 ou 6x4+5x5+3x3.
    cible = min(TARGET_SIZE, max_size)
    surplus = {s_: solver.IntVar(0, max(0, max_size - cible), f"sur_{s_[0]}_{s_[1]}")
               for s_ in slots}

    # manque d'élèves ayant classé, par groupe. Objectif souple : la taille des
    # groupes prime, donc on encaisse le manque plutôt que de créer un groupe de 5.
    manque = {s_: solver.IntVar(0, max_size, f"mq_{s_[0]}_{s_[1]}") for s_ in slots}


    # --- Contraintes
    # 1) Chaque élève est affecté exactement à un créneau
    for e in students:
        solver.Add(solver.Sum(x[(e, s)] for s in slots if (e, s) in x) == 1)

    # 2) Cohérence: pas d'affectation sur un créneau fermé
    for (e, s), var in x.items():
        solver.Add(var <= y[s])

    # 6bis) Un créneau réservé à une catégorie doit être ouvert. Sans cela le
    #       surdimensionnement de l'exception « groupe de 5 » serait mal borné.
    #       (les variables z sont créées plus bas, on prépare ici leur usage)
    pass

    # 3) Bornes min et max par créneau ouvert, avec l'exception des catégories de 5
    #    dont le créneau réservé peut accueillir un élève de plus.
    def cap_for(slot):
        extra = [z[g][slot] for g in exclusive if tailles_exclusives[g] == EXCEPTION_SIZE]
        return max_size * y[slot] + solver.Sum(extra) * (EXCEPTION_SIZE - max_size)

    # 4) Nombre de groupes
    if k_projects is not None:
        solver.Add(solver.Sum(y[s] for s in slots) == k_projects)

    # 5) Bris de symétrie entre créneaux interchangeables d'un même projet
    for p in projects:
        for k in range(n_slots[p] - 1):
            solver.Add(y[(p, k)] >= y[(p, k + 1)])

    # 5bis) Un minimum de projets retenus par catégorie. Le bris de symétrie
    #       ci-dessus garantit qu'un projet dont un créneau est ouvert a son
    #       premier créneau ouvert : y[(p, 0)] dit donc « ce projet est retenu »,
    #       et compter les projets ne revient pas à compter les groupes.
    for sujet, mini in sorted(exigences_sujets.items()):
        retenus = [y[(p, 0)] for p in projects if subject_of.get(p) == sujet]
        solver.Add(solver.Sum(retenus) >= mini)

    # 6) Groupes homogènes : un créneau marqué pour une catégorie exclusive
    #    n'accueille qu'elle, et ses élèves ne vont que sur des créneaux marqués.
    for g in exclusive:
        for s in slots:
            solver.Add(z[g][s] <= y[s])
            for e in students:
                if (e, s) not in x:
                    continue
                if speciality_of.get(e) == g:
                    solver.Add(x[(e, s)] <= z[g][s])
                else:
                    solver.Add(x[(e, s)] <= 1 - z[g][s])
    for s in slots:
        if len(exclusive) > 1:
            solver.Add(solver.Sum(z[g][s] for g in exclusive) <= 1)
        load_s = solver.Sum(x[(e, s)] for e in students if (e, s) in x)
        solver.Add(load_s <= cap_for(s))
        solver.Add(load_s <= cible * y[s] + surplus[s])
        solver.Add(load_s >= min_size * y[s])
        if min_choosers > 0:
            avec_voeux = solver.Sum(x[(e, s)] for e in choisisseurs if (e, s) in x)
            solver.Add(manque[s] >= min_choosers * y[s] - avec_voeux)

    ok = (pywraplp.Solver.OPTIMAL, pywraplp.Solver.FEASIBLE)
    etat = {"phase1": None, "phase2": None, "groupes": None, "borne_min": None,
            "proven_optimal": False}

    # --- Phase 1 : le moins de groupes possible, donc le plus de groupes de 4.
    #     C'est la règle prioritaire : elle passe avant les vœux.
    obj1 = solver.Objective()
    for s in slots:
        obj1.SetCoefficient(y[s], 1.0)
    obj1.SetMinimization()
    solver.SetTimeLimit(int(time_limit_s * 1000))
    status = solver.Solve()
    if status not in ok:
        raise RuntimeError("Modèle infaisable. Vérifiez les données/capacités.")
    etat["phase1"] = "optimal" if status == pywraplp.Solver.OPTIMAL else "faisable"

    n_groupes = k_projects if k_projects is not None else round(solver.Objective().Value())
    etat["groupes"] = n_groupes

    # Borne inférieure calculable : chaque catégorie exclusive occupe ses propres
    # groupes, le reste se remplit au mieux par paquets de max_size. Si la solution
    # l'atteint, elle est minimale — inutile d'attendre que CBC le prouve.
    reste = len(students) - sum(tailles_exclusives.values())
    borne = math.ceil(reste / max_size) if reste > 0 else 0
    for g, n in tailles_exclusives.items():
        borne += 1 if n == EXCEPTION_SIZE else math.ceil(n / max_size) if n else 0
    etat["borne_min"] = borne
    if n_groupes <= borne:
        etat["phase1"] = "optimal"
    xv = {k: v.solution_value() for k, v in x.items()}
    yv = {k: v.solution_value() for k, v in y.items()}

    # --- Phase 2 : à nombre de groupes fixé, satisfaire au mieux les vœux, en
    #     préférant des projets différents avant d'en doubler un.
    solver.Add(solver.Sum(y[s] for s in slots) == n_groupes)
    obj2 = solver.Objective()
    for (e, s), var in x.items():
        obj2.SetCoefficient(var, scores[(e, s[0])])
    # Dominant par construction : aucun gain de vœux ne peut payer un doublon.
    base = sum(scores.values()) + 1
    penalite = base * 100 if duplicate_penalty is None else duplicate_penalty
    for var in doublons:
        obj2.SetCoefficient(var, -float(penalite))
    for var in surplus.values():
        obj2.SetCoefficient(var, -float(base))
    for var in manque.values():
        obj2.SetCoefficient(var, -float(base))
    obj2.SetMaximization()

    solver.SetTimeLimit(int(time_limit_s * 1000))
    status2 = solver.Solve()
    if status2 in ok:
        etat["phase2"] = "optimal" if status2 == pywraplp.Solver.OPTIMAL else "faisable"
        xv = {k: v.solution_value() for k, v in x.items()}
        yv = {k: v.solution_value() for k, v in y.items()}
    else:
        etat["phase2"] = "abandonnée"

    etat["proven_optimal"] = etat["phase1"] == "optimal" and etat["phase2"] == "optimal"

    # --- Extraction de la solution
    selected: Set[str] = {labels[s] for s in slots if yv[s] > 0.5}
    assignment: Dict[str, List[str]] = {}
    for e in students:
        for s in slots:
            if (e, s) in x and xv[(e, s)] > 0.5:
                assignment.setdefault(labels[s], []).append(e)
                break

    assignment = {lbl: sorted(es) for lbl, es in assignment.items() if lbl in selected}

    final_score = sum(
        scores[(e, project_of_slot(lbl))]
        for lbl, es in assignment.items()
        for e in es
    )

    if return_status:
        return selected, assignment, final_score, scores, etat
    return selected, assignment, final_score, scores


def groups_by_project(assignment: Dict[str, List[str]]) -> Dict[str, List[List[str]]]:
    """Regroupe les créneaux d'un même projet : {projet: [[élèves], [élèves]]}."""
    out: Dict[str, List[List[str]]] = {}
    for label in sorted(assignment):
        out.setdefault(project_of_slot(label), []).append(assignment[label])
    return out


# --------- LIGNE DE COMMANDE ---------
#
#   python3 repartition.py
#
# Cherche le fichier payload-*.json déposé dans ce dossier, résout, et écrit
# assignment-*.json à côté. Ce dernier est le fichier à téléverser dans
# « Espace enseignant → Répartition des élèves → Importer ».

HERE = os.path.dirname(os.path.abspath(__file__))


def find_payload(explicit: Optional[str] = None) -> str:
    if explicit:
        path = explicit if os.path.isabs(explicit) else os.path.join(HERE, explicit)
        if not os.path.exists(path):
            raise SystemExit(f"Fichier introuvable : {path}")
        return path
    found = sorted(glob.glob(os.path.join(HERE, "payload-*.json")))
    if not found:
        raise SystemExit(
            "Aucun fichier payload-*.json dans ce dossier.\n"
            "Exportez-le depuis la page de la promo (Espace enseignant -> Répartition des\n"
            "élèves -> Exporter) et déposez-le ici, à côté de repartition.py."
        )
    if len(found) > 1:
        noms = "\n  ".join(os.path.basename(f) for f in found)
        raise SystemExit(f"Plusieurs fichiers payload-*.json, précisez lequel :\n  {noms}")
    return found[0]


def output_path(payload_path: str, explicit: Optional[str] = None) -> str:
    if explicit:
        return explicit if os.path.isabs(explicit) else os.path.join(HERE, explicit)
    base = os.path.basename(payload_path)
    name = base.replace("payload-", "assignment-", 1) if base.startswith("payload-") else "assignment.json"
    return os.path.join(HERE, name)


def summary(assignment: Dict[str, List[str]], score: float, payload: dict) -> str:
    spec = {e: (m or {}).get("speciality") for e, m in (payload.get("students") or {}).items()}
    sans = {g for g, m in (payload.get("specialities") or {}).items() if (m or {}).get("no_preference")}
    lignes = [f"{len(assignment)} groupes, score total {score:.0f}", ""]
    for project, groupes in sorted(groups_by_project(assignment).items()):
        for g in groupes:
            filieres = sorted({spec.get(e) for e in g if spec.get(e) and spec.get(e) not in sans})
            nb_sans = sum(1 for e in g if spec.get(e) in sans)
            suffixe = f"  [{', '.join(filieres)}]" if filieres else ""
            if nb_sans:
                suffixe += f" +{nb_sans} sans choix"
            lignes.append(f"  {len(g)}  {project[:44]}{suffixe}")
    total = sum(len(g) for g in assignment.values())
    tailles = {}
    for g in assignment.values():
        tailles[len(g)] = tailles.get(len(g), 0) + 1
    distincts = len(groups_by_project(assignment))
    detail = ", ".join(f"{n} groupe(s) de {t}" for t, n in sorted(tailles.items(), reverse=True))
    par_groupe = {}
    for g in assignment.values():
        n = sum(1 for e in g if spec.get(e) not in sans)
        par_groupe[n] = par_groupe.get(n, 0) + 1
    detail_c = ", ".join(f"{v} groupe(s) à {k}" for k, v in sorted(par_groupe.items(), reverse=True))
    lignes += ["", f"{total} élèves affectés — {detail}",
               f"élèves ayant classé par groupe : {detail_c}",
               f"{distincts} projets distincts utilisés sur {len(payload.get('projects') or {}) or distincts}"]
    return "\n".join(lignes)


def demo():
    import random
    random.seed(42)
    students = [f"E{i}" for i in range(1, 24)]
    all_projects = [f"P{j}" for j in range(1, 7)]
    scores = {}
    for e in students:
        for rank, p in enumerate(random.sample(all_projects, 6), start=1):
            scores[(e, p)] = 7 - rank
    selected, assignment, obj, _ = solve_assignment(
        scores, min_size=3, max_size=4, k_projects=None, lexicographic=True)
    print("=== démonstration sur données synthétiques ===")
    for p in sorted(assignment):
        print(f"{p}  (n={len(assignment[p])})  <- {assignment[p]}")
    print("Score total :", obj)


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Répartit les élèves d'une promo dans des groupes de projet.")
    ap.add_argument("payload", nargs="?",
                    help="fichier payload-*.json (auto-détecté dans ce dossier si omis)")
    ap.add_argument("-o", "--output", help="fichier de sortie (par défaut assignment-*.json)")
    ap.add_argument("--min-size", type=int, default=3, help="taille minimale d'un groupe (3)")
    ap.add_argument("--max-size", type=int, default=4, help="taille maximale d'un groupe (4)")
    ap.add_argument("--groupes", type=int, default=None,
                    help="impose un nombre exact de groupes (sinon minimisé)")
    ap.add_argument("--min-par-sujet", type=int, default=0,
                    help="nombre minimal de projets retenus dans chaque catégorie "
                         "(le subject des projets) ; 0 = pas de règle")
    ap.add_argument("--min-choosers", type=int, default=0,
                    help="objectif d'élèves ayant classé leurs vœux par groupe ; souple, "
                         "il cède devant la taille des groupes (0 = pas de règle)")
    ap.add_argument("--time-limit", type=float, default=60,
                    help="temps maximal par phase, en secondes (60)")
    ap.add_argument("--duplicate-penalty", type=float, default=None,
                    help="coût d'un 2e groupe sur un même projet (par défaut : dominant, "
                         "les doublons ne servent qu'en dernier recours)")
    ap.add_argument("--demo", action="store_true", help="tourne sur des données synthétiques")
    args = ap.parse_args(argv)

    if args.demo:
        return demo()

    payload_path = find_payload(args.payload)
    print(f"Entrée  : {os.path.basename(payload_path)}")
    with open(payload_path, encoding="utf-8") as f:
        payload = json.load(f)

    try:
        selected, assignment, score, _, etat = solve_assignment(
            payload, min_size=args.min_size, max_size=args.max_size,
            k_projects=args.groupes, time_limit_s=args.time_limit,
            duplicate_penalty=args.duplicate_penalty, min_choosers=args.min_choosers,
            min_per_subject=args.min_par_sujet, return_status=True)
    except (ValueError, RuntimeError) as exc:
        raise SystemExit(f"\nRépartition impossible.\n{exc}")

    out = output_path(payload_path, args.output)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(assignment, f, ensure_ascii=False, indent=1)

    print()
    print(summary(assignment, score, payload))
    if etat["phase1"] != "optimal":
        print()
        print(f"Note    : nombre minimal de groupes non prouvé en {args.time_limit:.0f} s.")
        print("          Il reste peut-être moins de groupes possible, donc plus de groupes de 4.")
    elif etat["phase2"] != "optimal":
        print()
        print(f"Note    : {etat['groupes']} groupes, c'est prouvé le minimum. En revanche le")
        print(f"          respect des vœux n'est pas prouvé optimal dans le délai de")
        print(f"          {args.time_limit:.0f} s ; relancez avec --time-limit plus élevé si besoin.")
    print()
    print(f"Sortie  : {os.path.basename(out)}")
    print("À téléverser dans Espace enseignant -> Répartition des élèves -> Importer.")


if __name__ == "__main__":
    main()
