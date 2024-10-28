import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

// Connects to data-controller="dragndrop"
export default class extends Controller {
  static targets = ["cards"]

  connect() {
    new Sortable(this.cardsTarget, {
      group: "cards",
      animation: 150,
      ghostClass: 'blue-background-class',
      onEnd: function (evt) { 
        const params = {
          id: evt.item.dataset.cardId,
          old_list: evt.from.dataset.listId,
          new_list: evt.to.dataset.listId,
          old_index: evt.oldIndex,
          new_index: evt.newIndex

        } 
        console.log(params);
        fetch("/update_card_position", {
          method: "PATCH",
          headers: { 
            "Content-Type": "application/json",
            "Accept": "application/json" },
          body: JSON.stringify(params)
        })
          .then(response => response.json())
          .then((data) => {
            const beginAt = evt.item.querySelector("#begin-at")
            const endAt = evt.item.querySelector("#end-at")
            beginAt.innerText = data.begin_at
            endAt.innerText = data.end_at
            if (beginAt.innerText && endAt.innerText) {
              evt.item.querySelector("#separator").innerText = " - ";
            }
          })
      }
    });
  }
}
