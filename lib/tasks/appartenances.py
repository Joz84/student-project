import re, json, sys
sys.path.insert(0, sys.argv[2] if len(sys.argv) > 2 else ".")
from lire_xlsx import charger

ETUDIANT = re.compile(r"^\s*(\d{8})\s*-\s*(.+?)\s*$")

def colonne_en_index(c):
    n = 0
    for ch in c:
        n = n * 26 + (ord(ch) - 64)
    return n

def extraire(chemin):
    classeur = charger(chemin)
    lignes_plates = []
    for feuille, lignes in classeur.items():
        if feuille == "Récapitulatif":
            continue
        for l in lignes:
            cells = sorted(l.items(), key=lambda kv: colonne_en_index(kv[0]))
            courant = None
            for col, val in cells:
                v = str(val).strip()
                m = ETUDIANT.match(v)
                if m:
                    courant = m.group(1)
                elif courant and v:
                    lignes_plates.append((feuille, courant, v))
    return lignes_plates

if __name__ == "__main__":
    plates = extraire(sys.argv[1])
    print("couples (étudiant, libellé) :", len(plates))
    par_feuille = {}
    for f, num, lab in plates:
        par_feuille.setdefault(f, {}).setdefault(lab, set()).add(num)
    for f, labs in par_feuille.items():
        print("\n--- %s ---" % f)
        for lab, nums in sorted(labs.items(), key=lambda kv: -len(kv[1])):
            print("    %-16s %3d étudiants" % (lab, len(nums)))
    json.dump([{"feuille": f, "num": n, "libelle": l} for f, n, l in plates],
              open("/tmp/appartenances.json", "w"), ensure_ascii=False)
