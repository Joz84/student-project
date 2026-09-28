# Rapatrie les emplois du temps ADE d'une promotion et les met en base.
#
# Une séance est reconnue à son créneau, son intitulé et sa salle, jamais à
# son UID : ADE en a changé le schéma en cours d'année et aucun identifiant
# d'un export ne se retrouvait dans le suivant, ce qui dupliquait tout le
# calendrier à chaque passage.
#
# Le flux fait autorité : une séance qu'il ne contient plus est supprimée,
# sauf si un appel y a déjà été fait — on ne détruit pas un registre.
class TimetableImporter
  Resultat = Struct.new(:creees, :majs, :inchangees, :supprimees, :conservees,
                        :ues, :groupes, :sans_enseignant, :erreurs, keyword_init: true) do
    def to_s
      texte = "#{creees} créées, #{majs} mises à jour, #{inchangees} inchangées"
      texte += ", #{supprimees} supprimées" if supprimees.to_i.positive?
      texte += ", #{conservees} retirées d'ADE mais conservées (appel fait)" if conservees.to_i.positive?
      texte + " · #{ues} UE, #{groupes} groupes · #{sans_enseignant} séances sans enseignant reconnu"
    end
  end

  def initialize(batch, codes)
    @batch = batch
    @codes = Array(codes)
  end

  def run(dry_run: false)
    creees = majs = inchangees = sans_prof = 0
    supprimees = conservees = 0
    erreurs = []
    ues = Set.new
    groupes = Set.new
    vues = Set.new

    ActiveRecord::Base.transaction do
      @codes.each do |code|
        seances = AdeCalendar.seances(AdeCalendar.telecharger(code))
        seances.each do |s|
          ue = s.ue.present? ? trouver_ue(s.ue) : nil
          ues << ue&.id
          enseignant = trouver_enseignant(s.enseignant)
          sans_prof += 1 if s.enseignant.present? && enseignant.nil?

          lesson = Lesson.find_or_initialize_by(
            batch: @batch, starts_at: s.debut, ends_at: s.fin,
            title: s.titre, room: s.salle
          )
          nouvelle = lesson.new_record?
          lesson.assign_attributes(
            ue: ue, teacher: enseignant, ade_uid: s.uid,
            teacher_label: s.enseignant, category: s.categorie
          )
          # 22 séances figurent dans les deux flux du portail, qui leur
          # donnent des UID différents : le seul changement d'UID ne dit rien
          # d'un changement d'emploi du temps.
          modifiee = (lesson.changed - ["ade_uid"]).any?
          lesson.save!

          ids = s.groupes.filter_map { |g| ue && trouver_groupe(ue, g).tap { |x| groupes << x.id } }.map(&:id)
          modifiee ||= lesson.group_ids.sort != ids.sort
          lesson.group_ids = ids

          vues << lesson.id
          if nouvelle then creees += 1
          elsif modifiee then majs += 1
          else inchangees += 1
          end
        rescue => e
          erreurs << "#{s.uid} : #{e.message}"
        end
      end

      # Réconciliation : ce que le flux ne contient plus n'a plus lieu. Les
      # feuilles ajoutées à la main sont hors de son autorité — elles existent
      # justement parce qu'ADE ne les connaît pas.
      disparues = Lesson.where(batch: @batch, manuelle: false).where.not(id: vues.to_a)
      avec_appel = disparues.joins(:attendances).distinct.pluck(:id)
      conservees = avec_appel.size
      # destroy_all et non delete_all : les rattachements aux groupes ont une
      # contrainte de clé étrangère, que seul le callback dependent nettoie.
      a_supprimer = Lesson.where(id: disparues.where.not(id: avec_appel).pluck(:id))
      supprimees = a_supprimer.count
      a_supprimer.destroy_all

      raise ActiveRecord::Rollback if dry_run
    end

    Resultat.new(creees: creees, majs: majs, inchangees: inchangees,
                 supprimees: supprimees, conservees: conservees,
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
  #
  # Certains n'y figurent pas sous le nom de leur compte — un changement d'état
  # civil qu'ADE n'a pas répercuté. `users.ade_label` porte alors le libellé
  # exact du flux, et prime sur le rapprochement par le nom : sans cela leurs
  # séances repartaient sans enseignant à chaque import, et ils ne voyaient
  # plus leurs cours.
  def trouver_enseignant(libelle)
    return nil if libelle.blank?
    charger_enseignants
    nom = libelle.sub(/\s*\((M\.|Mme)\)\s*\z/, "").strip
    @alias_ade[cle(libelle)] || @alias_ade[cle(nom)] ||
      @profs[cle(nom)] || @profs[cle(nom.split.rotate(-1).join(" "))]
  end

  def charger_enseignants
    return if @profs
    profs = User.where(teacher: true).to_a
    @profs = profs.index_by { |u| cle(u.last_name, u.first_name) }
    # Le libellé est indexé tel quel et sans la civilité : la scolarité le
    # recopie parfois avec, parfois sans.
    @alias_ade = {}
    profs.select { |u| u.ade_label.present? }.each do |u|
      @alias_ade[cle(u.ade_label)] = u
      @alias_ade[cle(u.ade_label.sub(/\s*\((M\.|Mme)\)\s*\z/, "").strip)] = u
    end
  end

  def cle(*parties) = I18n.transliterate(parties.join(" ")).downcase.gsub(/[^a-z]/, "")
end
