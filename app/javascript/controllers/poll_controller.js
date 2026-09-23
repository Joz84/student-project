import { Controller } from "@hotwired/stimulus"

// Rafraîchit une zone de la page à intervalle régulier. Utilisé par la feuille
// d'appel : l'enseignant voit les étudiants se signaler sans recharger.
// Le va-et-vient HTTP est préféré à un canal permanent, le dyno de production
// étant mono-processus et sans Redis.
export default class extends Controller {
  static targets = ["zone"]
  static values = { url: String, interval: Number, actif: Boolean }

  connect() {
    if (!this.actifValue) return
    this.timer = setInterval(() => this.rafraichir(), this.intervalValue || 5000)
    document.addEventListener("visibilitychange", this.suspendre)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.suspendre)
  }

  suspendre = () => {
    // Inutile d'interroger le serveur quand l'onglet n'est pas regardé.
    if (document.hidden) clearInterval(this.timer)
    else this.timer = setInterval(() => this.rafraichir(), this.intervalValue || 5000)
  }

  async rafraichir() {
    try {
      const reponse = await fetch(this.urlValue, { headers: { "Accept": "text/html" } })
      if (!reponse.ok) return
      this.zoneTarget.innerHTML = await reponse.text()
    } catch (e) {
      // Une coupure réseau ne doit pas casser la page : on retentera.
    }
  }
}
