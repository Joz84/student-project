import zipfile, re, sys
from xml.etree import ElementTree as ET

NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
R  = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"

def charger(chemin):
    z = zipfile.ZipFile(chemin)
    chaines = ["".join(t.text or "" for t in si.iter(NS + "t"))
               for si in ET.fromstring(z.read("xl/sharedStrings.xml"))]
    rels = {r.get("Id"): r.get("Target")
            for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))}
    wbk = ET.fromstring(z.read("xl/workbook.xml"))
    feuilles = []
    for s in wbk.find(NS + "sheets"):
        cible = rels[s.get(R + "id")].lstrip("/")
        if not cible.startswith("xl/"):
            cible = "xl/" + cible
        feuilles.append((s.get("name"), cible))

    resultat = {}
    for nom, cible in feuilles:
        racine = ET.fromstring(z.read(cible))
        lignes = []
        for row in racine.iter(NS + "row"):
            vals = {}
            for c in row.iter(NS + "c"):
                v = c.find(NS + "v")
                if v is None or v.text is None:
                    continue
                col = re.match(r"[A-Z]+", c.get("r")).group(0)
                vals[col] = chaines[int(v.text)] if c.get("t") == "s" else v.text
            if vals:
                lignes.append(vals)
        resultat[nom] = lignes
    return resultat

if __name__ == "__main__":
    classeur = charger(sys.argv[1])
    print("feuilles :", list(classeur))
    for nom, lignes in classeur.items():
        print("\n--- %s · %d lignes ---" % (nom, len(lignes)))
        for l in lignes[:6]:
            print("   ", {k: (v[:24] if v else v) for k, v in sorted(l.items())})
