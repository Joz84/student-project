import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chatroom"
export default class extends Controller {
  connect() {
    document.addEventListener("turbo:load", () => {
      window.scrollTo({
        top: document.body.scrollHeight,
        behavior: 'smooth', // Défilement fluide
      });
    });
  }
}
