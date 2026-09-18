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

  # Un CM concerne toute la promotion ; sinon seuls les groupes visés.
  def concerne?(user)
    return false unless user.batch_id == batch_id
    return true if groups.empty?
    (user.group_ids & group_ids).any?
  end

  def eleves_attendus
    return batch.users.kept.where(teacher: nil) if groups.empty?
    User.kept.where(teacher: nil).joins(:group_memberships)
        .where(group_memberships: { group_id: group_ids }).distinct
  end

  def verrouille? = locked_at.present?
  def valide?     = validated_at.present?

  def presents_count = attendances.where(status: :present).count
end
