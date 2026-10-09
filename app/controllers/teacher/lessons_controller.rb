# Feuille d'appel tenue par l'enseignant.
class Teacher::LessonsController < ApplicationController
  before_action :charger, except: [:new, :create]

  def show
  end

  # Certains enseignements ne figurent pas dans ADE — un rattrapage, un cours
  # ajouté en cours d'année, un créneau qui n'a jamais été publié. L'enseignant
  # crée alors sa feuille, choisit son cours dans la maquette, et fait l'appel
  # à l'oral en désignant les présents.
  def new
    @lesson = Lesson.new(starts_at: Time.current.change(min: 0), ends_at: 2.hours.from_now.change(min: 0))
    autoriser_creation
    charger_choix
  end

  def create
    @lesson = Lesson.new(parametres)
    @lesson.assign_attributes(teacher: current_user, manuelle: true, batch: @lesson.ue&.batch,
                              teacher_label: "#{current_user.last_name} #{current_user.first_name}")
    @lesson.title = intitule(@lesson)
    autoriser_creation

    if @lesson.batch.nil?
      @lesson.errors.add(:ue_id, "doit être choisie")
    elsif @lesson.save
      @lesson.group_ids = groupes_retenus(@lesson)
      return redirect_to teacher_lesson_path(@lesson), status: :see_other,
                         notice: "Feuille d'appel créée. Ajoutez les présents depuis « Ajouter un étudiant hors liste »."
    end

    charger_choix
    render :new, status: :unprocessable_entity
  end

  # Rafraîchissement de la liste, appelé toutes les cinq secondes par le
  # navigateur : l'enseignant voit les étudiants se signaler au fil de l'eau.
  def liste
    render partial: "teacher/lessons/liste", locals: { lesson: @lesson }
  end

  def ouvrir
    @lesson.ouvrir_pointage!
    redirect_to teacher_lesson_path(@lesson),
                notice: "Appel ouvert. Code à afficher : #{@lesson.attendance_code}", status: :see_other
  end

  def verrouiller
    @lesson.verrouiller!
    redirect_to teacher_lesson_path(@lesson), notice: "Pointages figés.", status: :see_other
  end

  def deverrouiller
    @lesson.deverrouiller!
    redirect_to teacher_lesson_path(@lesson), notice: "Les étudiants peuvent à nouveau se signaler.", status: :see_other
  end

  def rouvrir
    if @lesson.rouvrable?
      @lesson.rouvrir!
      redirect_to teacher_lesson_path(@lesson),
                  notice: "Appel rouvert : les étudiants peuvent à nouveau se signaler.", status: :see_other
    else
      redirect_to teacher_lesson_path(@lesson),
                  alert: "Le créneau est terminé. Corrigez depuis le bilan de présences.", status: :see_other
    end
  end

  # Quand toute la classe est là, renseigner les lignes une par une est une
  # perte de temps. Seuls les étudiants sans pointage sont touchés : une
  # absence déjà saisie ne doit pas être effacée par un raccourci.
  def tous_presents
    if @lesson.valide?
      return redirect_to teacher_lesson_path(@lesson), status: :see_other,
                         alert: "L'appel est validé : rouvrez-le pour le modifier."
    end

    ajoutes = 0
    ActiveRecord::Base.transaction do
      @lesson.eleves_attendus.each do |eleve|
        pointage = @lesson.pointage_de(eleve)
        next if pointage.persisted?
        pointage.update!(status: :present, declared_by: :teacher, declared_at: Time.current)
        ajoutes += 1
      end
    end

    message = if ajoutes.zero?
                "Tous les étudiants étaient déjà renseignés : rien n'a changé."
              else
                "#{ajoutes} étudiant#{'s' if ajoutes > 1} marqué#{'s' if ajoutes > 1} présent#{'s' if ajoutes > 1}."
              end
    redirect_to teacher_lesson_path(@lesson), notice: message, status: :see_other
  end

  # Une feuille créée à la main peut l'avoir été par erreur — mauvaise matière,
  # mauvais horaire. Elle laissait jusqu'ici une colonne parasite dans le relevé,
  # sans aucun moyen de la retirer.
  #
  # Les séances venues d'ADE ne se suppriment pas ici : le flux fait autorité,
  # et l'import les recréerait de toute façon la nuit suivante.
  def destroy
    unless @lesson.manuelle?
      return redirect_to teacher_lesson_path(@lesson), status: :see_other,
                         alert: "Cette séance vient de l'emploi du temps : elle ne se supprime pas ici."
    end

    if @lesson.attendances.any?
      return redirect_to teacher_lesson_path(@lesson), status: :see_other,
                         alert: "Des présences y sont déjà enregistrées. Effacez-les d'abord si la feuille est bien à retirer."
    end

    intitule = @lesson.title
    @lesson.destroy!
    redirect_to root_path, notice: "Feuille « #{intitule} » supprimée.", status: :see_other
  end

  # Déclarer qu'une séance n'a pas été pointée. Valider porterait tout le monde
  # absent, ce qui serait faux : un appel oublié ne dit rien de la présence des
  # étudiants, et doit se lire comme tel partout.
  def oublier
    efface = @lesson.attendances.count
    ActiveRecord::Base.transaction do
      @lesson.attendances.destroy_all
      @lesson.update!(attendance_code: nil, locked_at: nil, validated_at: nil)
    end

    suite = efface.positive? ? " #{efface} pointage#{'s' if efface > 1} effacé#{'s' if efface > 1}." : ""
    redirect_to root_path, status: :see_other,
                notice: "« #{@lesson.title} » est déclarée non renseignée.#{suite}"
  end

  def valider
    # Les attendus qui ne se sont pas signalés sont portés absents : sans cela
    # la séance resterait à moitié renseignée.
    ActiveRecord::Base.transaction do
      @lesson.eleves_attendus.each do |eleve|
        p = @lesson.pointage_de(eleve)
        p.status ||= :absent
        p.declared_by = :teacher if p.new_record?
        p.save!
      end
      @lesson.valider!
    end
    redirect_to teacher_lesson_path(@lesson),
                notice: "Appel validé : #{@lesson.presents_count} présents.", status: :see_other
  end

  private

  def autoriser_creation
    authorize [:teacher, @lesson], :new?
  end

  # Les promotions où l'enseignant intervient, plus celles qu'il supervise :
  # sans cela un vacataire nouvellement arrivé n'aurait aucune liste.
  def charger_choix
    ids = Lesson.where(teacher: current_user).distinct.pluck(:batch_id)
    ids |= current_user.supervised_batches.ids
    ids = Batch.where.not(title: "Equipe Pédagogique").ids if ids.empty? || current_user.admin
    @batches = Batch.where(id: ids).order(:title)
    @ues = Ue.where(batch: @batches).order(Arel.sql("position NULLS LAST"), :name).includes(:batch, :groups)
  end

  def parametres
    attrs = params.require(:lesson).permit(:ue_id, :room, :category)
    attrs.merge(starts_at: horodate(params[:debut]), ends_at: horodate(params[:fin]))
  end

  # Le formulaire sépare la date des heures : c'est plus sûr à saisir sur un
  # téléphone que deux champs date-et-heure. On les recompose ici, dans le
  # fuseau de l'application.
  def horodate(heure)
    jour = Date.parse(params[:jour].to_s)
    h, m = heure.to_s.split(":")
    Time.zone.local(jour.year, jour.month, jour.day, h.to_i, m.to_i)
  rescue ArgumentError, TypeError
    nil
  end

  def groupes_retenus(lesson)
    demandes = Array(params[:group_ids]).reject(&:blank?).map(&:to_i)
    # Un groupe d'une autre UE n'a rien à faire sur cette feuille.
    Group.where(id: demandes, ue_id: lesson.ue_id).ids
  end

  def intitule(lesson)
    return "Séance" if lesson.ue.nil?
    labels = Group.where(id: Array(params[:group_ids]).reject(&:blank?), ue_id: lesson.ue_id)
                  .order(:label).pluck(:label)
    labels.any? ? "#{labels.join(', ')} - #{lesson.ue.name}" : lesson.ue.name
  end

  def charger
    @lesson = Lesson.find(params[:id])
    authorize [:teacher, @lesson]
  end
end
