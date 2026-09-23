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

  # Un niveau non renseigné reste possible : on ne force personne à se situer.
  enum level: { notion: 0, initiation: 1, application: 2, maitrise: 3 }, _prefix: :niveau

  validates :user_id, uniqueness: { scope: :ue_id }
  validates :home_hours, numericality: { greater_than_or_equal_to: 0 }

  NOTES = { "notion" => 1, "initiation" => 2, "application" => 3, "maitrise" => 4 }.freeze

  def libelle = NIVEAUX[level]
  def note    = NOTES[level]

  # Sans niveau ni heures déclarées, la ligne n'a plus de raison d'être.
  def vide? = level.nil? && home_hours.to_f.zero?
end
