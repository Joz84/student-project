class Project < ApplicationRecord
  belongs_to :batch #, optional: true # remove after migration
  has_many :teams
  has_many :ratings
  has_many :project_specialities, dependent: :destroy
  has_many :specialities, through: :project_specialities
  has_many :supervisions
  has_many :teachers, through: :supervisions, source: :user
  validates :name, presence: true
  validates :description, presence: true

  # L'enum est positionnel : la colonne stocke l'indice. On ajoute donc
  # toujours à la fin — réordonner cette liste changerait la catégorie de
  # toutes les lignes existantes sans toucher à la base.
  enum subject: [ :physique, :chimie, :stes, :maths,
                  :regression_lineaire, :classification, :clustering, :deep_learning ]

  # La clé d'enum ne s'affiche pas telle quelle : « regression_lineaire »
  # capitalisé donnerait « Regression_lineaire ».
  LIBELLES_SUJETS = {
    "physique" => "Physique",
    "chimie" => "Chimie",
    "stes" => "STES",
    "maths" => "Maths",
    "regression_lineaire" => "Régression linéaire",
    "classification" => "Classification",
    "clustering" => "Clustering",
    "deep_learning" => "Deep learning"
  }.freeze

  def subject_label
    LIBELLES_SUJETS.fetch(subject.to_s) { subject.to_s.humanize }
  end

  before_create :initialize_color

  def kept_teams
    teams.merge(Team.kept)
  end

  def slug
    "#{id} -- #{name}"
  end

  def initialize_color
    r = rand(128..255)
    g = rand(128..255)
    b = rand(128..255)
    self.color = format("#%02X%02X%02X", r, g, b)
  end
end
