# Ce que l'étudiant déclare savoir faire sur une UE.
class UeAssessment < ApplicationRecord
  belongs_to :user
  belongs_to :ue

  # Échelle conventionnelle d'acquisition. Une seule constante à corriger si
  # le référentiel de la formation en retient une autre.
  NIVEAUX = {
    "notion"      => "Notion",
    "initiation"  => "Initiation",
    "application" => "Application",
    "maitrise"    => "Maîtrise"
  }.freeze

  AIDES = {
    "notion"      => "J'en ai entendu parler",
    "initiation"  => "Je sais faire avec de l'aide",
    "application" => "Je sais faire seul",
    "maitrise"    => "Je sais faire et l'expliquer"
  }.freeze

  enum level: { notion: 0, initiation: 1, application: 2, maitrise: 3 }, _prefix: :niveau

  validates :user_id, uniqueness: { scope: :ue_id }

  def libelle = NIVEAUX[level]
end
