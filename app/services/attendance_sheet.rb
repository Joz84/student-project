# Le tableau de bilan d'un enseignant pour une UE : une colonne par séance,
# une ligne par étudiant. Sert l'affichage, l'export et l'import, pour que
# les trois parlent exactement de la même grille.
class AttendanceSheet
  attr_reader :ue, :teacher, :lessons

  def initialize(teacher:, ue:, passees_seulement: false)
    @teacher = teacher
    @ue = ue
    scope = Lesson.where(teacher: teacher, ue: ue).includes(:groups)
    # Les séances à venir figurent elles aussi : un certificat médical arrive
    # souvent avant le cours, et il n'y a aucune raison d'attendre le jour dit
    # pour porter l'absence justifiée.
    if passees_seulement
      scope = scope.where("starts_at <= :t OR lessons.id IN (:avec)",
                          t: Time.current,
                          avec: Attendance.select(:lesson_id))
    end
    @lessons = scope.order(:starts_at).to_a
  end

  # Une séance qui n'a pas encore commencé : la colonne se lit autrement, on y
  # anticipe plutôt qu'on n'y constate.
  def future?(lesson) = lesson.starts_at > Time.current

  def passees = lessons.reject { |l| future?(l) }
  def a_venir = lessons.select { |l| future?(l) }

  # Les comptes ajoutés à la main sur la liste de la matière : un étudiant
  # d'un autre groupe, d'une autre promotion, ou que la scolarité n'a pas
  # rattaché. `permanent` dit s'il est attendu à chaque séance ou s'il ne
  # figure que dans ce relevé.
  def comptes_ajoutes
    @comptes_ajoutes ||= ue ? UeGuest.where(ue: ue).where.not(user_id: nil)
                                     .pluck(:user_id, :permanent).to_h : {}
  end

  def eleves
    @eleves ||= begin
      ids = attendus_par_seance.values.reduce(Set.new, :|)
      ids |= comptes_ajoutes.keys
      User.where(id: ids.to_a).order(:last_name, :first_name).to_a
    end
  end

  # La promotion, moins ceux qui figurent déjà dans la grille : ce qu'on peut
  # encore ajouter.
  def reste_de_la_promo
    return User.none if ue.nil?
    User.kept.where(teacher: nil, batch_id: ue.batch_id)
        .where.not(id: eleves.map(&:id))
        .order(:last_name, :first_name)
  end

  # Les lignes sans compte. Deux origines qui se rejoignent sur la même clé :
  # un pointage saisi pendant un appel, et une inscription faite à la main sur
  # la liste de la matière. Une personne ajoutée à la liste apparaît donc même
  # si elle n'a encore été pointée nulle part.
  Invite = Struct.new(:cle, :nom, :prenom, :numero, :pointages, keyword_init: true) do
    def libelle
      [prenom, nom].map(&:presence).compact.join(" ").presence&.titleize ||
        numero.presence || "Sans nom"
    end

    def statut(lesson_id) = pointages[lesson_id]&.status
  end

  def invites
    @invites ||= begin
      lignes = {}

      # Ce que la liste de la matière déclare.
      (ue ? UeGuest.where(ue: ue).order(:last_name, :first_name) : []).each do |g|
        lignes[g.cle] ||= Invite.new(cle: g.cle, nom: g.last_name, prenom: g.first_name,
                                     numero: g.student_number, pointages: {})
      end

      # Ce que les appels ont enregistré. Le libellé du pointage fait foi
      # quand la ligne n'a pas été déclarée : c'est la saisie la plus récente.
      Attendance.where(lesson_id: lessons.map(&:id), user_id: nil).each do |a|
        cle = UeGuest.cle_de(a.guest_last_name, a.guest_first_name, a.guest_student_number)
        ligne = lignes[cle] ||= Invite.new(cle: cle, nom: a.guest_last_name,
                                           prenom: a.guest_first_name,
                                           numero: a.guest_student_number, pointages: {})
        ligne.pointages[a.lesson_id] = a
      end

      lignes.values.sort_by { |i| [i.nom.to_s.downcase, i.prenom.to_s.downcase, i.numero.to_s] }
    end
  end

  def pointages
    @pointages ||= Attendance.where(lesson_id: lessons.map(&:id))
                             .where.not(user_id: nil)
                             .index_by { |a| [a.lesson_id, a.user_id] }
  end

  def statut(lesson, eleve) = pointages[[lesson.id, eleve.id]]&.status

  # Qui est attendu à quelle séance. Calculé une fois pour toute la grille :
  # une colonne de TP n'attend qu'un cinquième des lignes, et parcourir la
  # liste entière pour trouver son groupe est la première chose qui rend un
  # registre pénible à tenir.
  def attendus_par_seance
    @attendus_par_seance ||= begin
      avec_groupes, sans_groupes = lessons.partition { |l| l.group_ids.any? }

      par_groupe = GroupMembership
                   .where(group_id: avec_groupes.flat_map(&:group_ids).uniq)
                   .pluck(:group_id, :user_id)
                   .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(g, u), h| h[g] << u }

      # Les comptes inscrits sur toute la matière sont attendus partout ; ceux
      # ajoutés pour ce seul relevé apparaissent en ligne mais restent estompés.
      permanents = comptes_ajoutes.select { |_, p| p }.keys

      table = {}
      avec_groupes.each do |l|
        table[l.id] = (l.group_ids.flat_map { |g| par_groupe[g] } + permanents).to_set
      end

      unless sans_groupes.empty?
        promos = User.kept.where(teacher: nil, batch_id: sans_groupes.map(&:batch_id).uniq)
                     .pluck(:batch_id, :id)
                     .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(b, u), h| h[b] << u }
        auditeurs = ue ? GroupMembership.where(group_id: ue.group_ids).pluck(:user_id) : []
        sans_groupes.each do |l|
          table[l.id] = (promos[l.batch_id] + auditeurs + permanents).to_set
        end
      end
      table
    end
  end

  def attendu?(lesson, eleve) = attendus_par_seance[lesson.id]&.include?(eleve.id)

  def nombre_attendus(lesson) = attendus_par_seance[lesson.id]&.size.to_i

  def entete(lesson)
    "#{I18n.l(lesson.starts_at.to_date, format: '%d/%m')} #{lesson.starts_at.strftime('%H:%M')}"
  end

  def sous_entete(lesson)
    [lesson.groups.order(:label).map(&:label).join(", ").presence,
     lesson.room.presence].compact.join(" · ")
  end

  def vide? = lessons.empty?

  # Les intervenants qui ont au moins une séance rattachée à leur compte :
  # eux seuls ont un relevé à consulter.
  def self.enseignants_avec_seances
    User.where(id: Lesson.where.not(teacher_id: nil).select(:teacher_id))
        .order(:last_name, :first_name)
  end

  # Les UE pour lesquelles l'enseignant a au moins une séance.
  def self.ues_de(teacher)
    Ue.where(id: Lesson.where(teacher: teacher).where.not(ue_id: nil).select(:ue_id))
      .order(:name)
  end
end
