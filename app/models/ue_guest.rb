# Un étudiant ajouté à la main sur la liste d'une matière, sans compte.
#
# La clé de rapprochement est la même que pour les pointages saisis à la main :
# nom, prénom et numéro normalisés. C'est elle qui fait qu'une ligne ajoutée
# ici et un pointage pris en cours se retrouvent sur la même ligne du bilan.
class UeGuest < ApplicationRecord
  belongs_to :ue

  # Aucun champ n'est obligatoire pris isolément — l'enseignant saisit ce dont
  # il dispose, parfois un numéro seul — mais une ligne entièrement vide ne
  # désigne personne.
  validate :au_moins_un_champ

  def self.cle_de(nom, prenom, numero)
    [nom.to_s.strip.downcase, prenom.to_s.strip.downcase, numero.to_s.strip]
  end

  def cle = self.class.cle_de(last_name, first_name, student_number)

  def nom_complet
    [first_name, last_name].map(&:presence).compact.join(" ").presence ||
      student_number.presence || "Sans nom"
  end

  private

  def au_moins_un_champ
    return if [first_name, last_name, student_number].any?(&:present?)
    errors.add(:base, "Renseignez au moins un nom, un prénom ou un numéro.")
  end
end
