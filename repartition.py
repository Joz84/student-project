# -*- coding: utf-8 -*-
# Algorithme d'affectation élèves→projets avec groupes de 3 ou 4
# Objectif principal : maximiser la somme des notes
# Objectif secondaire (si K non fixé) : minimiser le nombre de projets (→ max de groupes de 4)
#
# Usage minimal : voir le bloc __main__ en bas.

from ortools.linear_solver import pywraplp
import math
from typing import Dict, Iterable, Tuple, List, Optional, Set
import json
import ast 


def solve_assignment(
    scores_json: str,
    students: Optional[Iterable[str]] = None,
    projects: Optional[Iterable[str]] = None,
    min_size: int = 3,
    max_size: int = 4,
    k_projects: Optional[int] = None,
    lexicographic: bool = True,
):
    """
    Résout l'affectation avec contraintes de taille de groupe ∈ [min_size, max_size].
    - scores: dict {(eleve, projet): note}  (ne mettez que les paires autorisées, ex: 10 choix/élève)
    - students: liste/itérable d'élèves (sinon déduit de scores)
    - projects: liste/itérable de projets (sinon déduit de scores)
    - min_size, max_size: tailles min et max par projet sélectionné (par défaut 3 et 4)
    - k_projects: si None → le solveur choisit K; sinon impose exactement K projets
    - lexicographic:
        * True  → 2 phases : (1) max score, (2) à score optimal, min #projets
        * False → une seule phase (max score) avec K fixé si fourni

    Retourne:
      selected_projects : set[str]
      assignment        : dict[str, list[str]]   (projet -> élèves)
      objective_value   : float                  (somme des notes)
    Lève ValueError si infaisable (ex: N ne peut pas être partitionné en [3..4]).
    """

    tmp_dict = json.loads(scores_json)
    scores = {tuple(ast.literal_eval(k)): v for k, v in tmp_dict.items()}

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

    # --- Si K n'est pas imposé, vérifier la faisabilité théorique : existe K tel que 3K <= N <= 4K
    K_min_feasible = math.ceil(N / max_size)
    K_max_feasible = math.floor(N / min_size)
    if k_projects is None:
        if K_min_feasible > K_max_feasible:
            raise ValueError(
                f"Impossible de former uniquement des groupes de {min_size}..{max_size} "
                f"avec N={N} élèves (aucun K tel que {min_size}K ≤ {N} ≤ {max_size}K)."
            )
    else:
        if not (min_size * k_projects <= N <= max_size * k_projects):
            raise ValueError(
                f"K={k_projects} incompatible avec N={N} et tailles [{min_size},{max_size}]. "
                f"Il faut {math.ceil(N/max_size)} ≤ K ≤ {math.floor(N/min_size)}."
            )

    # --- Construction du solveur
    solver = pywraplp.Solver.CreateSolver("CBC_MIXED_INTEGER_PROGRAMMING")
    if solver is None:
        raise RuntimeError("Impossible d'initialiser le solveur OR-Tools.")

    # --- Variables
    # x[e,p] = 1 si l'élève e est affecté au projet p (seulement pour paires autorisées)
    x = {}
    for e in students:
        for p in projects:
            if (e, p) in scores:
                x[(e, p)] = solver.BoolVar(f"x_{e}_{p}")

    # y[p] = 1 si le projet p est sélectionné (c'est un groupe ouvert)
    y = {p: solver.BoolVar(f"y_{p}") for p in projects}

    # --- Objectif (phase 1) : maximiser la somme des notes
    objective = solver.Objective()
    for (e, p), var in x.items():
        objective.SetCoefficient(var, scores[(e, p)])
    objective.SetMaximization()

    # --- Contraintes
    # 1) Chaque élève est affecté exactement à un projet
    for e in students:
        solver.Add(solver.Sum(x[(e, p)] for p in projects if (e, p) in scores) == 1)

    # 2) Cohérence: pas d'affectation sur un projet non sélectionné
    for (e, p), var in x.items():
        solver.Add(var <= y[p])

    # 3) Bornes min et max par projet sélectionné: min_size ≤ charge ≤ max_size si y[p]=1
    for p in projects:
        load_p = solver.Sum(x[(e, p)] for e in students if (e, p) in scores)
        solver.Add(load_p <= max_size * y[p])
        solver.Add(load_p >= min_size * y[p])

    # 4) Nombre de projets
    if k_projects is not None:
        solver.Add(solver.Sum(y[p] for p in projects) == k_projects)
    # sinon, libre; la phase 2 minimisera ∑y[p] si lexicographic=True

    # --- Phase 1 : Max score
    status = solver.Solve()
    if status not in (pywraplp.Solver.OPTIMAL, pywraplp.Solver.FEASIBLE):
        raise RuntimeError("Modèle infaisable. Vérifiez les données/capacités.")

    best_score = solver.Objective().Value()

    # --- Phase 2 (optionnelle) : à score optimal, minimiser le nombre de projets (→ max de 4)
    if k_projects is None and lexicographic:
        # Contrainte score ≥ best_score (tolérance pour flottants)
        eps = 1e-6
        # On ajoute une contrainte supplémentaire : somme(scores*x) ≥ best_score - eps
        score_expr = solver.Sum(scores[(e, p)] * x[(e, p)]
                                for (e, p) in x.keys())
        solver.Add(score_expr >= best_score - eps)

        # Nouveau objectif : minimiser ∑ y[p]
        new_obj = solver.Objective()
        for p in projects:
            new_obj.SetCoefficient(y[p], 1.0)
        new_obj.SetMinimization()

        status2 = solver.Solve()
        if status2 not in (pywraplp.Solver.OPTIMAL, pywraplp.Solver.FEASIBLE):
            # Très rare : si l'égalité stricte du score bloque, on retombe sur la solution phase 1
            pass

    # --- Extraction de la solution
    selected: Set[str] = {p for p in projects if y[p].solution_value() > 0.5}
    assignment: Dict[str, List[str]] = {p: [] for p in selected}
    for e in students:
        for p in projects:
            if (e, p) in scores and x[(e, p)].solution_value() > 0.5:
                assignment.setdefault(p, []).append(e)
                break

    # Tri pour lisibilité
    assignment = {p: sorted(es) for p, es in assignment.items() if p in selected}

    final_score = sum(
        scores[(e, p)]
        for p, es in assignment.items()
        for e in es
        if (e, p) in scores
    )

    return selected, assignment, final_score, scores


# --------- EXEMPLE D'UTILISATION ---------
if __name__ == "__main__":
    # Exemple synthétique :
    # - 23 élèves (E1..E23)
    # - 7 projets (P1..P7)
    # - Chaque élève n'autorise que 10 projets (ses préférences) avec des notes 10..1
    import random
    random.seed(42)

    students = [f"E{i}" for i in range(1, 24)]  # 25 élèves
    all_projects = [f"P{j}" for j in range(1, 7)]  # 12 projets
    scores = {}

    # On simule des préférences : chaque élève tire 7 projets distincts et reçoit des notes 6..1
    for e in students:
        prefs = random.sample(all_projects, 6)
        for rank, p in enumerate(prefs, start=1):
            scores[(e, p)] = 7 - rank  # 10 pour le 1er choix, 1 pour le 10e

    print("\n=== Inputs ===")
    print("students")
    print(students)
    print("all_projects")
    print(all_projects)  
    print("scores")
    print(scores)      


    # CAS 1 : K non fixé -> max score puis min #projets (max de groupes de 4)
    selected, assignment, obj = solve_assignment(
        scores,
        students=students,
        projects=all_projects,
        min_size=3,
        max_size=4,
        k_projects=None,        # laissez None pour que l'algo choisisse K
        lexicographic=True,     # et privilégie le minimum de projets à score optimal
    )

    print("\n=== Solution lexicographique (max score, puis max 4) ===")
    print("Projets sélectionnés :", sorted(selected), f"(K={len(selected)})")
    for p in sorted(assignment):
        print(f"{p}  (n={len(assignment[p])})  ← {assignment[p]}")
    print("Score total :", obj)

    # CAS 2 (optionnel) : imposer K = ceil(N/4) pour forcer le maximum possible de groupes de 4
    K_force = math.ceil(len(students) / 4)  # pour 25 → 7
    selected2, assignment2, obj2 = solve_assignment(
        scores,
        students=students,
        projects=all_projects,
        min_size=3,
        max_size=4,
        k_projects=K_force,     # force exactement K groupes
        lexicographic=False,    # une seule phase (le score est l'objectif)
    )
    print("\n=== Solution avec K fixé =", K_force, "(max de groupes de 4, règle dure) ===")
    print("Projets sélectionnés :", sorted(selected2), f"(K={len(selected2)})")
    for p in sorted(assignment2):
        print(f"{p}  (n={len(assignment2[p])})  ← {assignment2[p]}")
    print("Score total :", obj2)
