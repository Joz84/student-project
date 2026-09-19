# Une séance de cours, importée du flux ADE de l'université.
class Lesson < ApplicationRecord
  belongs_to :batch
  belongs_to :ue, optional: true
  belongs_to :teacher, class_name: "User", optional: true
  has_many :lesson_groups, dependent: :destroy
  has_many :groups, through: :lesson_groups
  has_many :attendances, dependent: :destroy

  # cm : toute la promotion ; autre : examens, rattrapages, événements divers.
  enum category: { cm: 0, td: 1, tp: 2, tp_info: 3, exam: 4, autre: 5 }

  validates :ade_uid, presence: true, uniqueness: true
  validates :title, :starts_at, :ends_at, presence: true

  scope :a_venir, -> { where("ends_at >= ?", Time.current).order(:starts_at) }
  scope :du_jour, -> { where(starts_at: Time.current.all_day).order(:starts_at) }

  def en_cours?(instant = Time.current)
    starts_at <= instant && instant <= ends_at
  end

  # L'assiduité se lit dans les groupes, jamais dans la promotion : un
  # redoublant peut suivre les enseignements d'une année tout en gardant son
  # projet dans une autre, et `users.batch_id` reste porté par le projet.
  #
  # Une séance de TD ou de TP vise ses groupes. Un CM n'en vise aucun : sont
  # alors attendus ceux qui suivent l'UE, c'est-à-dire les membres de l'un de
  # ses groupes. À défaut d'UE identifiée, on retombe sur la promotion.
  def concerne?(user)
    return false if user.nil? || user[:drop] || user.teacher?
    return (user.group_ids & group_ids).any? if groups.any?
    return user.group_ids.intersect?(ue.group_ids) if ue&.groups&.any?
    user.batch_id == batch_id
  end

  def eleves_attendus
    ids = groups.any? ? group_ids : ue&.group_ids
    return batch.users.kept.where(teacher: nil) if ids.blank?
    User.kept.where(teacher: nil).joins(:group_memberships)
        .where(group_memberships: { group_id: ids }).distinct
  end

  def verrouille? = locked_at.present?
  def valide?     = validated_at.present?

  def presents_count = attendances.where(status: :present).count
end
