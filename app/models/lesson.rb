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

  # L'UID d'ADE n'est qu'une trace : son schéma a changé en cours d'année et
  # il ne peut donc pas identifier une séance. Voir TimetableImporter.
  validates :title, :starts_at, :ends_at, presence: true
  validates :starts_at, uniqueness: { scope: [:batch_id, :ends_at, :title, :room],
                                      message: "cette séance est déjà enregistrée" }

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
    # Séance sans groupe — un CM, un examen : toute la promotion est concernée,
    # y compris les étudiants rattachés à aucun groupe de TD ou de TP. Un
    # auditeur venu d'une autre promotion ne l'est que s'il suit l'UE.
    return true if user.batch_id == batch_id
    ue.present? && user.group_ids.intersect?(ue.group_ids)
  end

  def eleves_attendus
    eleves = User.kept.where(teacher: nil)
    if groups.any?
      return eleves.joins(:group_memberships)
                   .where(group_memberships: { group_id: group_ids }).distinct
    end
    ids = eleves.where(batch_id: batch_id).ids
    if ue
      ids |= eleves.joins(:group_memberships)
                   .where(group_memberships: { group_id: ue.group_ids }).ids
    end
    User.where(id: ids)
  end

  def verrouille? = locked_at.present?
  def valide?     = validated_at.present?
  def pointage_ouvert? = attendance_code.present? && !verrouille? && !valide?

  def presents_count = attendances.where(status: :present).count

  # L'enseignant ouvre l'appel : un code à quatre chiffres s'affiche en salle
  # et devient exigible, ce qui empêche de se déclarer présent de chez soi.
  def ouvrir_pointage!
    update!(attendance_code: format("%04d", SecureRandom.random_number(10_000)),
            locked_at: nil)
  end

  def verrouiller!  = update!(locked_at: Time.current)
  def deverrouiller! = update!(locked_at: nil)
  def valider!      = update!(validated_at: Time.current, locked_at: locked_at || Time.current)

  # Tant que le créneau n'est pas écoulé, une validation reste réversible :
  # on valide souvent avant les derniers arrivants. Passée l'heure, la
  # correction se fait depuis le bilan, qui reste modifiable sans limite.
  def rouvrable?(instant = Time.current) = valide? && ends_at > instant

  def rouvrir!
    update!(validated_at: nil, locked_at: nil)
  end

  # Tous les étudiants de la promotion qui ne sont pas déjà attendus : un
  # rattrapage se fait dans le créneau d'un autre groupe.
  def eleves_hors_liste
    batch.users.kept.where(teacher: nil).where.not(id: eleves_attendus.select(:id))
         .order(:last_name, :first_name)
  end

  # Le pointage d'un étudiant, créé à la volée pour que la page de l'enseignant
  # affiche toujours la liste complète des attendus.
  def pointage_de(user)
    attendances.find_or_initialize_by(user: user)
  end
end
