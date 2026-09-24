import { Controller } from "@hotwired/stimulus"

// Filtre une liste déjà présente dans la page. Utilisé par la feuille d'appel :
// l'enseignant qui cherche un étudiant venu en rattrapage n'a pas le temps
// d'attendre un aller-retour serveur devant sa classe.
export default class extends Controller {
  static targets = ["champ", "ligne", "compteur", "vide"]

  connect() {
    this.filtrer()
  }

  filtrer() {
    const requete = this.normaliser(this.champTarget.value)
    let visibles = 0

    this.ligneTargets.forEach((ligne) => {
      const texte = this.normaliser(ligne.dataset.recherche || ligne.textContent)
      const trouve = requete === "" || texte.includes(requete)
      ligne.hidden = !trouve
      if (trouve) visibles += 1
    })

    if (this.hasCompteurTarget) this.compteurTarget.textContent = visibles
    if (this.hasVideTarget) this.videTarget.hidden = visibles > 0
  }

  // Les noms portent accents et apostrophes ; personne ne les tape dans une
  // barre de recherche. On compare des chaînes dépouillées de part et d'autre.
  normaliser(texte) {
    return (texte || "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/['’ʻ-]/g, "")
      .toLowerCase()
      .trim()
  }
}
