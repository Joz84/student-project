# Le libellé sous lequel ADE nomme un enseignant, quand il diffère du nom du
# compte. Marania Hopuare y figure sous son nom d'avant, « Klouman Marania » :
# le rapprochement automatique ne la retrouvait pas, et ses séances restaient
# sans enseignant à chaque import.
class AddAdeLabelToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :ade_label, :string
    add_index  :users, :ade_label
  end
end
