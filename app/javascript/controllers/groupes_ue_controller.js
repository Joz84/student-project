import { Controller } from "@hotwired/stimulus"

// Sur le formulaire de création d'une feuille d'appel, n'afficher que les
// groupes du cours choisi. Tous sont rendus par le serveur : la promotion en
// compte quelques dizaines, inutile d'aller les chercher au clic.
export default class extends Controller {
  static targets = ["ue", "ligne", "vide"]

  connect() {
    this.filtrer()
  }

  filtrer() {
    const choisie = this.ueTarget.value
    let visibles = 0

    this.ligneTargets.forEach((ligne) => {
      const garde = choisie !== "" && ligne.dataset.ue === choisie
      ligne.hidden = !garde
      // Un groupe masqué ne doit pas rester coché : il partirait au serveur.
      if (!garde) ligne.querySelector("input[type=checkbox]").checked = false
      if (garde) visibles += 1
    })

    if (this.hasVideTarget) {
      this.videTarget.hidden = visibles > 0
      this.videTarget.querySelector("small").textContent =
        choisie === ""
          ? "Choisissez d'abord un cours ci-dessus."
          : "Ce cours n'a aucun groupe : la feuille partira vide."
    }
  }
}
