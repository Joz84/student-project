# Un étudiant ajouté à la main sur la liste d'une matière, sans compte.
#
# La clé de rapprochement est la même que pour les pointages saisis à la main :
# nom, prénom et numéro normalisés. C'est elle qui fait qu'une ligne ajoutée
# ici et un pointage pris en cours se retrouvent sur la même ligne du bilan.
class UeGuest < ApplicationRecord
  belongs_to :ue
  # Une ligne peut désigner un compte — un étudiant d'une autre promotion, ou
  # rattaché à aucun groupe — plutôt qu'une identité saisie à la main.
  belongs_to :user, optional: true
  # Le groupe auquel l'ajout se limite. Nul vise toute la matière, ce qui
  # reste utile pour un auditeur qui suit tout.
  belongs_to :group, optional: true

  # Portée de l'ajout : une ligne permanente est attendue à chaque séance de la
  # matière, une ligne ponctuelle ne figure que dans le relevé.
  scope :permanentes, -> { where(permanent: true) }

  # Aucun champ n'est obligatoire pris isolément — l'enseignant saisit ce dont
  # il dispose, parfois un numéro seul — mais une ligne entièrement vide ne
  # désigne personne.
  validate :au_moins_un_champ
  validates :user_id, uniqueness: { scope: :ue_id }, if: -> { user_id.present? }

  def self.cle_de(nom, prenom, numero)
    [nom.to_s.strip.downcase, prenom.to_s.strip.downcase, numero.to_s.strip]
  end

  def cle
    return nil if user_id.present?
    self.class.cle_de(last_name, first_name, student_number)
  end

  # La portée, dite en français, pour les messages et les listes.
  def portee = group ? group.label : "toute la matière"

  def nom_complet
    return "#{user.first_name} #{user.last_name}" if user
    [first_name, last_name].map(&:presence).compact.join(" ").presence ||
      student_number.presence || "Sans nom"
  end

  private

  def au_moins_un_champ
    return if user_id.present?
    return if [first_name, last_name, student_number].any?(&:present?)
    errors.add(:base, "Renseignez au moins un nom, un prénom ou un numéro.")
  end
end
