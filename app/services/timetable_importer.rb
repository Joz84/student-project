# Rapatrie les emplois du temps ADE d'une promotion et les met en base.
# L'UID de chaque séance étant stable, l'import est réidempotent : on le
# rejoue tous les soirs sans créer de doublon, et une séance déplacée par la
# scolarité voit simplement son horaire mis à jour.
class TimetableImporter
  Resultat = Struct.new(:creees, :majs, :inchangees, :ues, :groupes,
                        :sans_enseignant, :erreurs, keyword_init: true) do
    def to_s
      "#{creees} créées, #{majs} mises à jour, #{inchangees} inchangées · " \
      "#{ues} UE, #{groupes} groupes · #{sans_enseignant} séances sans enseignant reconnu"
    end
  end

  def initialize(batch, codes)
    @batch = batch
    @codes = Array(codes)
  end

  def run(dry_run: false)
    creees = majs = inchangees = sans_prof = 0
    erreurs = []
    ues = Set.new
    groupes = Set.new

    ActiveRecord::Base.transaction do
      @codes.each do |code|
        seances = AdeCalendar.seances(AdeCalendar.telecharger(code))
        seances.each do |s|
          ue = s.ue.present? ? trouver_ue(s.ue) : nil
          ues << ue&.id
          enseignant = trouver_enseignant(s.enseignant)
          sans_prof += 1 if s.enseignant.present? && enseignant.nil?

          lesson = Lesson.find_or_initialize_by(ade_uid: s.uid)
          nouvelle = lesson.new_record?
          lesson.assign_attributes(
            batch: @batch, ue: ue, teacher: enseignant,
            title: s.titre, room: s.salle, teacher_label: s.enseignant,
            category: s.categorie, starts_at: s.debut, ends_at: s.fin
          )
          modifiee = lesson.changed?
          lesson.save!

          ids = s.groupes.filter_map { |g| ue && trouver_groupe(ue, g).tap { |x| groupes << x.id } }.map(&:id)
          modifiee ||= lesson.group_ids.sort != ids.sort
          lesson.group_ids = ids

          if nouvelle then creees += 1
          elsif modifiee then majs += 1
          else inchangees += 1
          end
        rescue => e
          erreurs << "#{s.uid} : #{e.message}"
        end
      end
      raise ActiveRecord::Rollback if dry_run
    end

    Resultat.new(creees: creees, majs: majs, inchangees: inchangees,
                 ues: ues.compact.size, groupes: groupes.size,
                 sans_enseignant: sans_prof, erreurs: erreurs)
  end

  private

  def trouver_ue(nom)
    @ues_cache ||= {}
    @ues_cache[nom] ||= Ue.find_or_create_by!(batch: @batch, name: nom)
  end

  def trouver_groupe(ue, g)
    @groupes_cache ||= {}
    @groupes_cache[[ue.id, g[:label]]] ||=
      Group.find_or_create_by!(ue: ue, label: g[:label]) { |x| x.kind = g[:kind] }
  end

  # ADE écrit « Serafini Jonathan (M.) », nous stockons prénom et nom séparés.
  def trouver_enseignant(libelle)
    return nil if libelle.blank?
    @profs ||= User.where(teacher: true).index_by { |u| cle(u.last_name, u.first_name) }
    nom = libelle.sub(/\s*\((M\.|Mme)\)\s*\z/, "").strip
    @profs[cle(nom)] || @profs[cle(nom.split.rotate(-1).join(" "))]
  end

  def cle(*parties) = I18n.transliterate(parties.join(" ")).downcase.gsub(/[^a-z]/, "")
end
