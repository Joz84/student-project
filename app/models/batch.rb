class Batch < ApplicationRecord
  has_many :users
  has_many :referentials, dependent: :destroy
  has_many :specialities, -> { order(:position) }, dependent: :destroy
  has_many :projects
  has_many :teachers, through: :projects
  validates :title, presence: true, uniqueness: true

  def discord_server_url
    "https://discord.com/channels/#{discord_server_id}" if discord_server_id.present?
  end

  def current_referential
    referentials.find_by(active: true)
  end

  def project_slugs
    projects.map(&:slug)
  end

  def user_slugs
    users.map(&:slug)
  end

  # Score normalisé par élève : son 1er vœu vaut 100, son dernier 0, quelle que
  # soit la longueur de sa liste. Sans ça un étudiant Maths, qui ne classe que
  # 3 projets, verrait son dernier vœu mieux noté que le 8e vœu d'un SI qui en
  # classe 14 — et le solveur sacrifierait d'abord les préférences des Maths.
  def self.normalized_score(position, count)
    return 100 if position.nil? || count.to_i <= 1
    ((count - position) * 100.0 / (count - 1)).round
  end

  def scores
    ratings_scores(users)
  end

  # Attrait de chaque projet, tel que les élèves l'ont classé jusqu'ici.
  def project_demand(user_scope = users.kept.where(teacher: nil))
    ratings = Rating.where(user: user_scope).to_a
    tailles = ratings.group_by(&:user_id).transform_values(&:size)
    cumul = Hash.new { |h, k| h[k] = { ranked: 0, first: 0, top3: 0, sum: 0 } }
    ratings.each do |r|
      d = cumul[r.project_id]
      d[:ranked] += 1
      d[:first]  += 1 if r.position == 1
      d[:top3]   += 1 if r.position && r.position <= 3
      d[:sum]    += self.class.normalized_score(r.position, tailles[r.user_id])
    end
    projects.map { |p|
      d = cumul[p.id]
      { project: p,
        ranked: d[:ranked],
        first: d[:first],
        top3: d[:top3],
        mean: d[:ranked].zero? ? nil : (d[:sum].to_f / d[:ranked]).round,
        teams: p.max_booking || 1,
        seats: (p.max_booking || 1) * TeamsImporter::MAX_SIZE }
    }.sort_by { |h| [-(h[:mean] || -1), h[:project].name] }
  end

  # Pseudo-spécialité des élèves qui n'ont pas validé leur classement : aucune
  # préférence, accès à tous les projets. Ils viennent compléter les groupes.
  SANS_CHOIX = "sans-choix".freeze

  # Entrée complète du solveur (repartition_algorithme/repartition.py).
  # Contrairement à `scores`, ne retient que les étudiants encore présents.
  def solver_payload(student_scope = users.kept.where(teacher: nil))
    ayant_choisi = student_scope.booked
    sans_choix = student_scope.pending

    notes = ratings_scores(ayant_choisi)
    sans_choix.each do |u|
      projects.each { |p| notes[[u.slug, p.slug]] = 0 }
    end

    filieres = specialities.map { |s| [s.slug, { exclusive_groups: s.exclusive_groups }] }.to_h
    # Ils ne sont plus groupés entre eux : ils complètent les groupes, et la
    # contrainte min_choosers du solveur garantit assez d'élèves ayant classé.
    filieres[SANS_CHOIX] = { exclusive_groups: false, no_preference: true } if sans_choix.any?

    {
      scores: notes,
      projects: projects.map { |p| [p.slug, { max_booking: p.max_booking || 1 }] }.to_h,
      students: student_scope.map { |u|
        [u.slug, { speciality: u.pending? ? SANS_CHOIX : u.speciality&.slug }]
      }.to_h,
      specialities: filieres
    }
  end

  private

  def ratings_scores(user_scope)
    ratings = Rating.where(user: user_scope).includes(:user, :project).to_a
    tailles = ratings.group_by(&:user_id).transform_values(&:size)
    ratings.map { |r|
      [[r.user.slug, r.project.slug],
       self.class.normalized_score(r.position, tailles[r.user_id])]
    }.to_h
  end

end
