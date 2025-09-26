# -*- coding: utf-8 -*-
import pandas as pd
import numpy as np
from matplotlib.colors import LinearSegmentedColormap


# ===== Fonction de style : encadrement des cellules assignées =====
def highlight_assigned(dataframe: pd.DataFrame, assignations) -> pd.DataFrame:
    styles = pd.DataFrame("", index=dataframe.index, columns=dataframe.columns)
    # Inverser la dict pour trouver, pour chaque étudiant, son projet assigné
    etu_to_proj = {}
    for p, etus in assignations.items():
        for e in etus:
            etu_to_proj[e] = p
    # Appliquer le bord noir épais
    for e, p in etu_to_proj.items():
        if e in styles.index and p in styles.columns:
            styles.loc[e, p] = "border: 3px solid black"
    return styles

def viz(scores, assignations, html):

    # ===== Construction du DataFrame pivoté (lignes E??, colonnes P??) =====
    df = pd.Series(scores).unstack()  # colonnes = P??, index = E??
    # Tri naturel E1..E23 et P1..P6
    df = df.loc[sorted(df.index, key=lambda x: int(x.split(' -- ', 1)[0])),
                sorted(df.columns, key=lambda x: int(x.split(' -- ', 1)[0]))]

    # ===== Colormap blanc -> vert foncé =====
    # (blanc pour les plus faibles, vert foncé pour les plus forts)
    cmap = LinearSegmentedColormap.from_list(
        "white_to_green",
        ["#ffffff", "#a5d6a7", "#66bb6a", "#2e7d32"]  # clair -> foncé
    )

    # ===== Création du Styler =====
    styler = (
        df.style
        .format("{:.0f}")                         
        .background_gradient(cmap=cmap, axis=None)
        .apply(lambda df_: highlight_assigned(df_, assignations), axis=None)
        .set_properties(**{"text-align": "center"})
        .set_table_styles([
            {"selector": "th", "props": [("text-align", "center")]},
            {"selector": "td", "props": [("min-width", "3em"), ("height", "2.2em")]},
            {"selector": "table", "props": [("border-collapse", "collapse"),
                                            ("font-family", "sans-serif")]}
        ])
    )

    # ===== Export HTML autonome =====
    if html == True:
        html_path = "assignations.html"
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(styler.to_html())

        print(f"Fichier HTML généré : {html_path}")
    
    return styler