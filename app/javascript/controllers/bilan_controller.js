import { Controller } from "@hotwired/stimulus"

// Enregistre chaque case du relevé dès qu'elle change.
//
// La grille compte des centaines de cases : les envoyer toutes à chaque
// modification serait absurde, et attendre un bouton final fait perdre la
// saisie d'un enseignant qui quitte la page. On n'envoie donc que la case
// touchée, et la couleur suit aussitôt.
export default class extends Controller {
  static targets = ["bouton", "etat"]
  static values = { url: String, ue: Number }

  connect() {
    // Le bouton n'a de sens que sans JavaScript : ici il induirait en erreur.
    if (this.hasBoutonTarget) this.boutonTarget.hidden = true
    if (this.hasEtatTarget) this.etatTarget.hidden = false
  }

  async enregistrer(evenement) {
    const champ = evenement.target
    const cellule = champ.closest("td")
    const corps = new URLSearchParams()
    corps.append("_method", "patch")
    corps.append("ue_id", this.ueValue)
    corps.append("cellule", "1")
    corps.append(champ.name, champ.value)

    // Une ligne sans compte est retrouvée sur son identité, pas sur un
    // identifiant : il faut la renvoyer avec la case.
    const ligne = champ.closest("tr")
    ligne.querySelectorAll("input[type=hidden]").forEach((h) => corps.append(h.name, h.value))

    this.signaler(cellule, "en-cours")
    try {
      const reponse = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content || "",
          "Accept": "text/plain"
        },
        body: corps.toString(),
        credentials: "same-origin"
      })
      if (!reponse.ok) throw new Error(reponse.status)
      this.teinter(cellule, champ.value)
      this.signaler(cellule, "ok")
    } catch (e) {
      // L'enseignant doit savoir que sa saisie n'est pas partie.
      this.signaler(cellule, "erreur")
      if (this.hasEtatTarget) {
        this.etatTarget.textContent = "Enregistrement impossible — vérifiez votre connexion."
        this.etatTarget.classList.add("bilan__etat--erreur")
      }
    }
  }

  teinter(cellule, statut) {
    if (!cellule) return
    cellule.className = cellule.className
      .split(" ")
      .filter((c) => !c.startsWith("bilan__case--") || c === "bilan__case--hors")
      .concat(`bilan__case--${statut || "vide"}`)
      .join(" ")
  }

  signaler(cellule, etat) {
    if (!cellule) return
    cellule.dataset.etat = etat
    if (etat === "ok") setTimeout(() => { delete cellule.dataset.etat }, 900)
  }
}
