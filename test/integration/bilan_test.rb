require "test_helper"

class BilanTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    @batch  = Batch.create!(title: "Promo bilan #{SecureRandom.hex(4)}")
    @ue     = Ue.create!(batch: @batch, name: "Mécanique")
    @autre  = Ue.create!(batch: @batch, name: "Chimie")
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @prof   = User.create!(email: "prof-#{SecureRandom.hex(4)}@upf.pf", first_name: "Pro",
                           last_name: "Fesseur", student_number: "12345678", teacher: true,
                           batch: @batch, password: "motdepasse")
    @a = eleve("10000001", "Ata")
    @b = eleve("10000002", "Bta")
    [@a, @b].each { |e| GroupMembership.create!(user: e, group: @groupe) }

    @s1 = seance(@ue, 8.days.ago, "TD-01 - Mécanique")
    @s2 = seance(@ue, 1.day.ago,  "TD-01 - Mécanique")
    @futur = seance(@ue, 3.days.from_now, "TD-01 - à venir")
    seance(@autre, 2.days.ago, "CM - Chimie", groupe: nil)
  end

  test "la grille montre un onglet par UE et toutes les séances" do
    sign_in @prof
    get teacher_bilan_path
    assert_response :success
    assert_match "Mécanique", response.body
    assert_match "Chimie", response.body

    # L'onglet ouvert par défaut est le premier dans l'ordre alphabétique.
    get teacher_bilan_path(ue_id: @ue.id)
    assert_match @s1.starts_at.strftime("%d/%m"), response.body
    assert_match @s2.starts_at.strftime("%d/%m"), response.body
    # Un certificat arrive souvent avant le cours : la colonne d'une séance à
    # venir doit exister pour qu'on puisse y porter l'absence tout de suite.
    assert_match @futur.starts_at.strftime("%d/%m"), response.body
    assert_match "bilan__seance--future", response.body, "elle se distingue des séances passées"
  end

  test "une séance à venir se renseigne dès maintenant" do
    sign_in @prof
    patch teacher_bilan_path, params: { ue_id: @ue.id, cellule: "1",
      statuts: { @futur.id.to_s => { @a.id.to_s => "excused" } } }

    assert_equal 204, response.status
    assert_equal "excused", Attendance.find_by(lesson: @futur, user: @a).status
  end

  test "la grille est pré-remplie par les appels déjà faits" do
    Attendance.create!(lesson: @s1, user: @a, status: :present, declared_by: :student)
    sign_in @prof
    get teacher_bilan_path(ue_id: @ue.id)
    assert_match "bilan__case--present", response.body
  end

  test "enregistrer la grille écrit, modifie et efface" do
    sign_in @prof
    patch teacher_bilan_path, params: {
      ue_id: @ue.id,
      statuts: { @s1.id.to_s => { @a.id.to_s => "present", @b.id.to_s => "excused" } }
    }
    assert_equal "present", Attendance.find_by(lesson: @s1, user: @a).status
    assert_equal "excused", Attendance.find_by(lesson: @s1, user: @b).status

    patch teacher_bilan_path, params: {
      ue_id: @ue.id, statuts: { @s1.id.to_s => { @a.id.to_s => "retard", @b.id.to_s => "" } }
    }
    assert_equal "retard", Attendance.find_by(lesson: @s1, user: @a).status
    assert_nil Attendance.find_by(lesson: @s1, user: @b), "une case vidée efface le pointage"
  end

  test "l'export produit la grille, l'import la relit" do
    Attendance.create!(lesson: @s1, user: @a, status: :present, declared_by: :teacher)
    sign_in @prof
    get export_teacher_bilan_path(ue_id: @ue.id)
    assert_response :success
    csv = response.body.sub("﻿", "")
    entete = AttendanceSheetExport.entete(@s1)
    assert_match entete, csv
    assert_match "Présent", csv

    # On modifie le fichier hors ligne, comme le ferait un enseignant.
    modifie = csv.sub("Présent", "AJ").sub("#{@b.student_number};#{@b.last_name}",
                                           "#{@b.student_number};#{@b.last_name}")
    lignes = modifie.lines
    lignes[2] = lignes[2].chomp + "" if lignes[2]
    fichier = deposer(modifie.gsub(/(#{@b.student_number};[^\n]*?);;/) { "#{$1};R;" })

    post import_teacher_bilan_path, params: { ue_id: @ue.id, fichier: fichier }
    assert_equal "excused", Attendance.find_by(lesson: @s1, user: @a).status, "AJ devient une absence justifiée"
  end

  test "un fichier dont les colonnes ne correspondent pas est refusé" do
    sign_in @prof
    post import_teacher_bilan_path,
         params: { ue_id: @ue.id, fichier: deposer("Numéro;Nom;Prénom;01/01/1990 08:00\n123;X;Y;P\n") }
    assert_match(/aucune colonne de séance reconnue/, flash[:alert])
  end

  test "l'import comprend plusieurs façons d'écrire un statut" do
    sign_in @prof
    entete = AttendanceSheetExport.entete(@s1)
    contenu = "Numéro;Nom;Prénom;#{entete}\n" \
              "#{@a.student_number};A;A;p\n#{@b.student_number};B;B;Absent justifié\n"
    post import_teacher_bilan_path, params: { ue_id: @ue.id, fichier: deposer(contenu) }
    assert_equal "present", Attendance.find_by(lesson: @s1, user: @a).status
    assert_equal "excused", Attendance.find_by(lesson: @s1, user: @b).status
  end

  test "les cases hors du groupe de la séance sont estompées" do
    # Un CM fait entrer toute la promotion dans la grille ; la colonne de TD,
    # elle, ne concerne que son groupe.
    hors = eleve("10000003", "Cta")
    cm = seance(@ue, 2.days.ago, "CM - Mécanique", groupe: nil)
    cm.lesson_groups.destroy_all

    sheet = AttendanceSheet.new(teacher: @prof, ue: @ue)
    assert_includes sheet.eleves, hors, "le CM fait entrer toute la promotion"
    assert sheet.attendu?(cm, hors), "le CM concerne toute la promotion"
    refute sheet.attendu?(@s1, hors), "le TD ne concerne que son groupe"
    assert sheet.attendu?(@s1, @a)
    assert_equal 2, sheet.nombre_attendus(@s1)
    assert_equal 3, sheet.nombre_attendus(cm)

    sign_in @prof
    get teacher_bilan_path(ue_id: @ue.id)
    assert_match "bilan__case--hors", response.body
    assert_match "bilan__attendus", response.body
  end

  test "une case hors groupe reste modifiable, pour un rattrapage" do
    hors = eleve("10000004", "Dta")
    cm = seance(@ue, 2.days.ago, "CM - Mécanique", groupe: nil)
    cm.lesson_groups.destroy_all
    sign_in @prof
    patch teacher_bilan_path, params: {
      ue_id: @ue.id, statuts: { @s1.id.to_s => { hors.id.to_s => "present" } }
    }
    assert_equal "present", Attendance.find_by(lesson: @s1, user: hors).status
  end

  # Jusqu'ici une ligne sans compte n'existait qu'au travers d'un pointage :
  # impossible d'inscrire quelqu'un sans le déclarer présent quelque part.
  test "l'enseignant ajoute un étudiant à la liste de la matière" do
    sign_in @prof
    assert_difference -> { UeGuest.count }, 1 do
      post eleve_teacher_bilan_path, params: { ue_id: @ue.id,
        guest_first_name: "Vaiana", guest_last_name: "Tepuhiarii",
        guest_student_number: "20260999" }
    end
    assert_redirected_to teacher_bilan_path(ue_id: @ue.id)

    get teacher_bilan_path(ue_id: @ue.id)
    assert_match "Vaiana Tepuhiarii", response.body
    assert_match "ajouté à la main", response.body
    assert_equal 0, Attendance.where(user_id: nil).count, "l'ajout ne pointe personne"
  end

  test "un seul des trois champs suffit" do
    sign_in @prof
    assert_difference -> { UeGuest.count }, 1 do
      post eleve_teacher_bilan_path, params: { ue_id: @ue.id, guest_student_number: "20260888" }
    end
    get teacher_bilan_path(ue_id: @ue.id)
    assert_match "20260888", response.body
  end

  test "une ligne entièrement vide est refusée" do
    sign_in @prof
    assert_no_difference -> { UeGuest.count } do
      post eleve_teacher_bilan_path, params: { ue_id: @ue.id, guest_first_name: " " }
    end
    assert_match(/au moins un nom/, flash[:alert])
  end

  test "les séances d'un étudiant ajouté se renseignent depuis la grille" do
    UeGuest.create!(ue: @ue, first_name: "Vaiana", last_name: "Tepuhiarii",
                    student_number: "20260999")
    sign_in @prof

    patch teacher_bilan_path, params: { ue_id: @ue.id, invites: { "0" => {
      nom: "Tepuhiarii", prenom: "Vaiana", numero: "20260999",
      statuts: { @s1.id.to_s => "present", @s2.id.to_s => "excused" }
    } } }

    assert_equal 2, Attendance.where(user_id: nil).count
    assert_equal "present", Attendance.find_by(lesson: @s1, user_id: nil).status
    assert_equal "excused", Attendance.find_by(lesson: @s2, user_id: nil).status

    # Vider une case efface le pointage, comme pour un compte.
    patch teacher_bilan_path, params: { ue_id: @ue.id, invites: { "0" => {
      nom: "Tepuhiarii", prenom: "Vaiana", numero: "20260999",
      statuts: { @s1.id.to_s => "" }
    } } }
    assert_nil Attendance.find_by(lesson: @s1, user_id: nil)
    assert_equal 1, Attendance.where(user_id: nil).count
  end

  test "un pointage pris pendant l'appel rejoint la ligne de la liste" do
    UeGuest.create!(ue: @ue, first_name: "Vaiana", last_name: "Tepuhiarii",
                    student_number: "20260999")
    # L'enseignant l'avait aussi saisi pendant un appel, avec la même identité.
    @s1.attendances.create!(guest_first_name: "Vaiana", guest_last_name: "Tepuhiarii",
                            guest_student_number: "20260999", status: :present,
                            declared_by: :teacher)

    sheet = AttendanceSheet.new(teacher: @prof, ue: @ue)
    assert_equal 1, sheet.invites.size, "une seule ligne, pas deux"
    assert_equal "present", sheet.invites.first.statut(@s1.id)
  end

  test "un étudiant ne peut pas ajouter de ligne" do
    sign_in @a
    assert_no_difference -> { UeGuest.count } do
      post eleve_teacher_bilan_path, params: { ue_id: @ue.id, guest_last_name: "Intrus" }
    end
    assert_redirected_to root_path
  end

  # Attendre un bouton final fait perdre la saisie d'un enseignant qui quitte
  # la page. Chaque case part seule, et la réponse reste vide : le navigateur
  # a déjà mis la couleur à jour.
  test "une case envoyée seule est enregistrée sans recharger la page" do
    sign_in @prof
    patch teacher_bilan_path, params: { ue_id: @ue.id, cellule: "1",
      statuts: { @s1.id.to_s => { @a.id.to_s => "present" } } }

    assert_equal 204, response.status
    assert_empty response.body
    assert_equal "present", Attendance.find_by(lesson: @s1, user: @a).status
  end

  test "une case vidée seule efface le pointage" do
    @s1.attendances.create!(user: @a, status: :present, declared_by: :teacher)
    sign_in @prof
    patch teacher_bilan_path, params: { ue_id: @ue.id, cellule: "1",
      statuts: { @s1.id.to_s => { @a.id.to_s => "" } } }

    assert_equal 204, response.status
    assert_nil Attendance.find_by(lesson: @s1, user: @a)
  end

  test "une case d'un étudiant ajouté à la main part aussi seule" do
    UeGuest.create!(ue: @ue, first_name: "Vaiana", last_name: "Tepuhiarii",
                    student_number: "20260999")
    sign_in @prof
    patch teacher_bilan_path, params: { ue_id: @ue.id, cellule: "1",
      invites: { "0" => { nom: "Tepuhiarii", prenom: "Vaiana", numero: "20260999",
                          statuts: { @s1.id.to_s => "retard" } } } }

    assert_equal 204, response.status
    assert_equal "retard", Attendance.find_by(lesson: @s1, user_id: nil).status
  end

  test "l'enregistrement d'ensemble reste possible sans JavaScript" do
    sign_in @prof
    patch teacher_bilan_path, params: { ue_id: @ue.id,
      statuts: { @s1.id.to_s => { @a.id.to_s => "present" } } }

    assert_redirected_to teacher_bilan_path(ue_id: @ue.id)
    assert_match(/enregistrée/, flash[:notice])
  end

  test "la question de portée ne parle plus d'un relevé à choisir" do
    sign_in @prof
    get teacher_bilan_path(ue_id: @ue.id)
    assert_match "Faut-il l'attendre aux prochaines séances ?", response.body
    assert_match "Non, seulement dans ce tableau", response.body
    refute_match "Ce relevé seulement", response.body
  end

  # L'administrateur dépanne les collègues : il ne peut pas le faire à l'aveugle.
  test "l'administrateur consulte le relevé d'un autre intervenant" do
    admin = creer_prof("Serafini")
    admin.update!(admin: true)
    sign_in admin

    get teacher_bilan_path(teacher_id: @prof.id, ue_id: @ue.id)
    assert_response :success
    assert_match "Relevé de", response.body
    assert_match "relevé d'un collègue", response.body
    assert_match @a.last_name, response.body, "les étudiants du collègue s'affichent"
  end

  test "il peut y écrire, et la case part au bon nom" do
    admin = creer_prof("Serafini")
    admin.update!(admin: true)
    sign_in admin

    patch teacher_bilan_path, params: { teacher_id: @prof.id, ue_id: @ue.id, cellule: "1",
      statuts: { @s1.id.to_s => { @a.id.to_s => "present" } } }
    assert_equal 204, response.status
    assert_equal "present", Attendance.find_by(lesson: @s1, user: @a).status
  end

  test "un enseignant ordinaire ne voit que le sien, même en forçant l'adresse" do
    autre = creer_prof("Adam")
    seance_autre = Lesson.create!(batch: @batch, ue: @autre, teacher: autre,
                                  title: "TD - Chimie", starts_at: 2.days.ago,
                                  ends_at: 2.days.ago + 2.hours)
    seance_autre.attendances.create!(user: @a, status: :present, declared_by: :teacher)

    sign_in @prof
    get teacher_bilan_path(teacher_id: autre.id, ue_id: @autre.id)
    assert_response :success
    refute_match "Relevé de", response.body, "le sélecteur ne lui est pas proposé"

    # La grille servie reste la sienne : la séance du collègue n'y est pas.
    sienne = AttendanceSheet.new(teacher: @prof, ue: @autre)
    refute_includes sienne.lessons.map(&:id), seance_autre.id
    assert_equal sienne.lessons.size,
                 response.body.scan("bilan__seance").size,
                 "autant de colonnes que de séances qui lui appartiennent"
  end

  test "le sélecteur ne liste que les intervenants ayant des séances" do
    sans_seance = creer_prof("Sansrien")
    admin = creer_prof("Serafini")
    admin.update!(admin: true)
    sign_in admin

    get teacher_bilan_path
    assert_match @prof.last_name.upcase, response.body
    refute_match sans_seance.last_name.upcase, response.body
  end

  # Un étudiant d'un autre groupe qu'on a en cours doit pouvoir entrer dans la
  # grille, sans qu'on lui invente une appartenance de TD.
  test "l'enseignant ajoute un étudiant de la promotion au relevé" do
    hors = creer_eleve("85000001", "Horsgroupe")   # même promo, pas dans @groupe
    sign_in @prof

    get teacher_bilan_path(ue_id: @ue.id)
    assert_match "Ajouter un étudiant de la promotion", response.body
    assert_match hors.student_number, response.body
    assert_match 'data-controller="filtre"', response.body, "la même recherche que sur la feuille d'appel"

    # Les deux boutons disent ce qu'ils font, pas où ils écrivent.
    assert_match "Présence exceptionnelle", response.body
    assert_match "Ajouter aux feuilles de présences", response.body
    refute_match "Ce relevé", response.body
    refute_match "Toute la matière", response.body

    # Le ponctuel vient en premier, l'ajout durable ensuite et mis en avant.
    assert_operator response.body.index("Présence exceptionnelle"), :<,
                    response.body.index("Ajouter aux feuilles de présences")

    assert_difference -> { UeGuest.count }, 1 do
      post eleve_teacher_bilan_path, params: { ue_id: @ue.id, user_id: hors.id, portee: "matiere" }
    end
    invite = UeGuest.last
    assert_equal hors, invite.user
    assert invite.permanent?

    get teacher_bilan_path(ue_id: @ue.id)
    assert_match hors.last_name, response.body
    refute_match "Ajouter un étudiant de la promotion\n", response.body.sub(hors.last_name, "")
  end

  test "ajouté pour ce relevé seulement, il reste estompé sur les colonnes" do
    hors = creer_eleve("85000002", "Ponctuel")
    sign_in @prof
    post eleve_teacher_bilan_path, params: { ue_id: @ue.id, user_id: hors.id, portee: "releve" }

    sheet = AttendanceSheet.new(teacher: @prof, ue: @ue)
    assert_includes sheet.eleves.map(&:id), hors.id, "il a sa ligne"
    refute sheet.attendu?(@s1, hors), "mais il n'est pas attendu aux séances"
  end

  test "inscrit sur toute la matière, il est attendu partout" do
    hors = creer_eleve("85000003", "Permanent")
    sign_in @prof
    post eleve_teacher_bilan_path, params: { ue_id: @ue.id, user_id: hors.id, portee: "matiere" }

    sheet = AttendanceSheet.new(teacher: @prof, ue: @ue)
    assert sheet.attendu?(@s1, hors)
    assert sheet.attendu?(@futur, hors)
  end

  test "l'ajouter deux fois ne fait pas deux lignes" do
    hors = creer_eleve("85000004", "Doublon")
    sign_in @prof
    2.times { post eleve_teacher_bilan_path, params: { ue_id: @ue.id, user_id: hors.id, portee: "matiere" } }
    assert_equal 1, UeGuest.where(ue: @ue, user: hors).count
  end

  test "un étudiant déjà dans la grille n'est plus proposé" do
    sign_in @prof
    get teacher_bilan_path(ue_id: @ue.id)
    bloc = response.body[/ajoutPromo.*?<\/ul>/m].to_s
    refute_match @a.student_number, bloc, "il est déjà dans la grille par son groupe"
  end

  test "un étudiant n'accède pas au bilan" do
    sign_in @a
    get teacher_bilan_path
    assert_redirected_to root_path
  end

  private

  def eleve(numero, nom)
    User.create!(email: "e-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "X",
                 last_name: nom, student_number: numero, batch: @batch, password: "motdepasse")
  end

  def seance(ue, debut, titre, groupe: @groupe)
    l = Lesson.create!(batch: @batch, ue: ue, teacher: @prof, ade_uid: SecureRandom.hex(8),
                       title: titre, category: :td, starts_at: debut, ends_at: debut + 90.minutes)
    LessonGroup.create!(lesson: l, group: groupe) if groupe && ue == @ue
    l
  end

  def deposer(contenu)
    f = Tempfile.new(["grille", ".csv"])
    f.write(contenu)
    f.rewind
    Rack::Test::UploadedFile.new(f.path, "text/csv", original_filename: "grille.csv")
  end
end
