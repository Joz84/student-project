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


def slot_label(project: str, index: int, n_slots: int) -> str:
    return project if n_slots == 1 else f"{project}{SLOT_SEP}{index + 1}"


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
                       speciality_of, exclusive):
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

    # Une spécialité à groupes homogènes doit pouvoir se partitionner seule.
    for g in exclusive:
        n = sum(1 for e in students if speciality_of.get(e) == g)
        if math.ceil(n / max_size) > math.floor(n / min_size):
            raise ValueError(
                f"La spécialité '{g}' impose des groupes homogènes mais compte {n} élève(s), "
                f"ce qui ne se partitionne pas en groupes de {min_size} à {max_size}."
            )


def solve_assignment(
    scores_json,
    students: Optional[Iterable[str]] = None,
    projects: Optional[Iterable[str]] = None,
    min_size: int = 3,
    max_size: int = 4,
    k_projects: Optional[int] = None,
    lexicographic: bool = True,
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

    _check_feasibility(students, projects, scores, n_slots,
                       min_size, max_size, k_projects, speciality_of, exclusive)

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

    # --- Objectif (phase 1) : maximiser la somme des notes
    objective = solver.Objective()
    for (e, s), var in x.items():
        objective.SetCoefficient(var, scores[(e, s[0])])
    objective.SetMaximization()

    # --- Contraintes
    # 1) Chaque élève est affecté exactement à un créneau
    for e in students:
        solver.Add(solver.Sum(x[(e, s)] for s in slots if (e, s) in x) == 1)

    # 2) Cohérence: pas d'affectation sur un créneau fermé
    for (e, s), var in x.items():
        solver.Add(var <= y[s])

    # 3) Bornes min et max par créneau ouvert
    for s in slots:
        load_s = solver.Sum(x[(e, s)] for e in students if (e, s) in x)
        solver.Add(load_s <= max_size * y[s])
        solver.Add(load_s >= min_size * y[s])

    # 4) Nombre de groupes
    if k_projects is not None:
        solver.Add(solver.Sum(y[s] for s in slots) == k_projects)

    # 5) Bris de symétrie entre créneaux interchangeables d'un même projet
    for p in projects:
        for k in range(n_slots[p] - 1):
            solver.Add(y[(p, k)] >= y[(p, k + 1)])

    # 6) Groupes homogènes : un créneau marqué pour une spécialité exclusive
    #    n'accueille qu'elle, et ses élèves ne vont que sur des créneaux marqués.
    z = {}
    for g in exclusive:
        z[g] = {s: solver.BoolVar(f"z_{g}_{s[0]}_{s[1]}") for s in slots}
        for s in slots:
            for e in students:
                if (e, s) not in x:
                    continue
                if speciality_of.get(e) == g:
                    solver.Add(x[(e, s)] <= z[g][s])
                else:
                    solver.Add(x[(e, s)] <= 1 - z[g][s])
    if len(exclusive) > 1:
        for s in slots:
            solver.Add(solver.Sum(z[g][s] for g in exclusive) <= 1)

    # --- Phase 1 : Max score
    status = solver.Solve()
    if status not in (pywraplp.Solver.OPTIMAL, pywraplp.Solver.FEASIBLE):
        raise RuntimeError("Modèle infaisable. Vérifiez les données/capacités.")

    best_score = solver.Objective().Value()

    # --- Phase 2 (optionnelle) : à score optimal, minimiser le nombre de groupes
    if k_projects is None and lexicographic:
        eps = 1e-6
        score_expr = solver.Sum(scores[(e, s[0])] * x[(e, s)] for (e, s) in x.keys())
        solver.Add(score_expr >= best_score - eps)

        new_obj = solver.Objective()
        for s in slots:
            new_obj.SetCoefficient(y[s], 1.0)
        new_obj.SetMinimization()

        status2 = solver.Solve()
        if status2 not in (pywraplp.Solver.OPTIMAL, pywraplp.Solver.FEASIBLE):
            # Très rare : on retombe sur la solution phase 1
            pass

    # --- Extraction de la solution
    selected: Set[str] = {labels[s] for s in slots if y[s].solution_value() > 0.5}
    assignment: Dict[str, List[str]] = {}
    for e in students:
        for s in slots:
            if (e, s) in x and x[(e, s)].solution_value() > 0.5:
                assignment.setdefault(labels[s], []).append(e)
                break

    assignment = {lbl: sorted(es) for lbl, es in assignment.items() if lbl in selected}

    final_score = sum(
        scores[(e, project_of_slot(lbl))]
        for lbl, es in assignment.items()
        for e in es
    )

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
    lignes = [f"{len(assignment)} groupes, score total {score:.0f}", ""]
    for project, groupes in sorted(groups_by_project(assignment).items()):
        for g in groupes:
            filieres = sorted({spec.get(e) for e in g if spec.get(e)})
            suffixe = f"  [{', '.join(filieres)}]" if filieres else ""
            lignes.append(f"  {len(g)}  {project[:52]}{suffixe}")
    total = sum(len(g) for g in assignment.values())
    lignes += ["", f"{total} élèves affectés"]
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
    ap.add_argument("--demo", action="store_true", help="tourne sur des données synthétiques")
    args = ap.parse_args(argv)

    if args.demo:
        return demo()

    payload_path = find_payload(args.payload)
    print(f"Entrée  : {os.path.basename(payload_path)}")
    with open(payload_path, encoding="utf-8") as f:
        payload = json.load(f)

    try:
        selected, assignment, score, _ = solve_assignment(
            payload, min_size=args.min_size, max_size=args.max_size,
            k_projects=args.groupes, lexicographic=args.groupes is None)
    except (ValueError, RuntimeError) as exc:
        raise SystemExit(f"\nRépartition impossible.\n{exc}")

    out = output_path(payload_path, args.output)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(assignment, f, ensure_ascii=False, indent=1)

    print()
    print(summary(assignment, score, payload))
    print()
    print(f"Sortie  : {os.path.basename(out)}")
    print("À téléverser dans Espace enseignant -> Répartition des élèves -> Importer.")


if __name__ == "__main__":
    main()
