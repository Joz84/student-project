# Crée les équipes d'une promo à partir de la sortie du solveur de répartition
# (repartition_algorithme/repartition.py).
#
# Entrée : le dictionnaire `assignment`, {libellé de créneau => [slugs d'élèves]}.
#   { "34 -- Totem || groupe 1" => ["339 -- Moehei Tama", "340 -- ..."], ... }
# Le suffixe « || groupe N » n'apparaît que si plusieurs groupes partagent un projet.
#
#   importer = TeamsImporter.new(Batch.find(67), json)
#   puts importer.run(dry_run: true).report   # vérifie sans rien écrire
#   puts importer.run.report                  # crée pour de bon
#
# Rien n'est écrit si une seule erreur est détectée, et la création est
# transactionnelle : soit toutes les équipes, soit aucune.
class TeamsImporter
  MIN_SIZE = 3
  MAX_SIZE = 4
  SLOT_SEP = " || groupe "
  WAITING_TEAM = "En attente de projet"

  Group = Struct.new(:project, :members, :label, keyword_init: true)

  class Result
    attr_reader :errors, :warnings, :groups, :teams, :unassigned, :dry_run

    def initialize(errors:, warnings:, groups:, teams:, unassigned:, dry_run:)
      @errors, @warnings, @groups = errors, warnings, groups
      @teams, @unassigned, @dry_run = teams, unassigned, dry_run
    end

    def ok? = errors.empty?

    def report
      out = []
      out << (ok? ? (dry_run ? "SIMULATION — rien n'a été écrit" : "#{teams.size} équipes créées")
                  : "ÉCHEC — rien n'a été écrit")
      errors.each   { |e| out << "  ERREUR  #{e}" }
      warnings.each { |w| out << "  ATTENTION #{w}" }
      unless groups.empty?
        out << ""
        groups.each do |g|
          noms = g.members.map { |u| u.first_name }.join(", ")
          out << "  #{g.members.size}  #{g.project.name[0, 46].ljust(46)} #{noms}"
        end
      end
      if unassigned.any?
        out << ""
        out << "  #{unassigned.size} étudiant(s) hors répartition, laissés en attente :"
        unassigned.each { |u| out << "     #{u.slug}" }
      end
      out.join("\n")
    end
  end

  def initialize(batch, assignment, min_size: MIN_SIZE, max_size: MAX_SIZE)
    @batch = batch
    @raw = assignment.is_a?(String) ? JSON.parse(assignment) : assignment
    @min_size = min_size
    @max_size = max_size
    @errors = []
    @warnings = []
  end

  def run(dry_run: false)
    groups = build_groups
    check(groups)
    teams = []
    if @errors.empty?
      # requires_new: true force un SAVEPOINT. Sans lui, un appel imbriqué dans une
      # transaction existante rejoindrait la transaction parente et ActiveRecord::Rollback
      # y serait ignoré : la simulation écrirait pour de bon.
      ActiveRecord::Base.transaction(requires_new: true) do
        teams = groups.each_with_index.map { |g, i| create_team(g, groups, i) }
        raise ActiveRecord::Rollback if dry_run
      end
    end
    Result.new(errors: @errors, warnings: @warnings, groups: groups,
               teams: teams, unassigned: unassigned(groups), dry_run: dry_run)
  end

  private

  def students = @students ||= @batch.users.kept.where(teacher: nil).index_by(&:id)

  def id_of(slug) = slug.to_s.split(" -- ").first.to_i

  def build_groups
    @raw.map do |label, slugs|
      project = @batch.projects.find_by(id: id_of(label.split(SLOT_SEP).first))
      @errors << "projet inconnu dans cette promo : #{label}" if project.nil?
      members = Array(slugs).map do |s|
        u = students[id_of(s)]
        @errors << "étudiant introuvable dans la promo : #{s}" if u.nil?
        u
      end.compact
      Group.new(project: project, members: members, label: label)
    end.select { |g| g.project }
  end

  def check(groups)
    existing = Team.joins(:users).where(users: { batch_id: @batch.id })
                   .where.not(name: WAITING_TEAM).distinct
    if existing.any?
      @errors << "#{existing.count} équipe(s) existent déjà pour cette promo " \
                 "(#{existing.limit(3).pluck(:name).join(', ')}…) — supprimez-les avant de réimporter"
    end

    seen = Hash.new(0)
    groups.each { |g| g.members.each { |u| seen[u.id] += 1 } }
    seen.select { |_, n| n > 1 }.each_key do |id|
      @errors << "étudiant affecté à plusieurs groupes : #{students[id].slug}"
    end

    groups.each do |g|
      n = g.members.size
      unless n.between?(@min_size, @max_size)
        @errors << "groupe de #{n} sur « #{g.project.name} » (attendu #{@min_size} à #{@max_size})"
      end

      hors = g.members.reject { |u| u.eligible_projects.exists?(g.project.id) }
      hors.each do |u|
        @errors << "#{u.slug} (#{u.speciality&.slug || 'sans spécialité'}) n'a pas accès à " \
                   "« #{g.project.name} »"
      end

      exclusives = g.members.map(&:speciality).compact.select(&:exclusive_groups?).uniq
      exclusives.each do |spe|
        intrus = g.members.reject { |u| u.speciality_id == spe.id }
        if intrus.any?
          @errors << "« #{g.project.name} » mêle #{spe.slug} et #{intrus.map { |u| u.speciality&.slug || '?' }.uniq.join(', ')} " \
                     "alors que #{spe.slug} impose des groupes homogènes"
        end
      end
    end

    groups.group_by(&:project).each do |project, gs|
      quota = project.max_booking || 1
      if gs.size > quota
        @errors << "#{gs.size} groupes sur « #{project.name} » pour un max_booking de #{quota}"
      end
    end
  end

  def unassigned(groups)
    placed = groups.flat_map(&:members).map(&:id).to_set
    students.values.reject { |u| placed.include?(u.id) }.sort_by(&:id)
  end

  def create_team(group, all_groups, index)
    same = all_groups.select { |g| g.project == group.project }
    rank = same.index(group) + 1
    leader = group.members.min_by(&:id)
    team = Team.create!(name: available_name(group.project, rank, same.size),
                        project: group.project, user: leader)
    group.members.each { |u| u.update!(team: team) }
    team
  end

  def available_name(project, rank, total)
    base = total > 1 ? "#{project.name} #{rank}" : project.name
    candidate = base
    n = 1
    while Team.exists?(name: candidate)
      n += 1
      candidate = "#{base} (#{n})"
    end
    candidate
  end
end
