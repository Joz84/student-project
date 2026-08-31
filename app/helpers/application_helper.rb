module ApplicationHelper
  # Dégradé blanc -> vert foncé de viz.py, réutilisé pour la matrice de répartition.
  RANK_RAMP = ["#ffffff", "#a5d6a7", "#66bb6a", "#2e7d32"].freeze

  # Le rang est normalisé par la longueur de la liste de l'élève : le 1er vœu
  # d'un étudiant Maths (3 projets) et celui d'un SI (15) valent la même chose.
  def rank_ratio(position, total)
    return nil if position.nil?
    return 1.0 if total.to_i <= 1
    (total - position).to_f / (total - 1)
  end

  def rank_color(position, total)
    t = rank_ratio(position, total)
    return nil if t.nil?
    span = 1.0 / (RANK_RAMP.size - 1)
    i = [(t / span).floor, RANK_RAMP.size - 2].min
    a, b = RANK_RAMP[i], RANK_RAMP[i + 1]
    f = (t - i * span) / span
    rgb = (0..2).map do |k|
      av = a[1 + 2 * k, 2].to_i(16)
      bv = b[1 + 2 * k, 2].to_i(16)
      (av + (bv - av) * f).round
    end
    format("#%02X%02X%02X", *rgb)
  end

  def rank_text_color(position, total)
    t = rank_ratio(position, total)
    t && t > 0.55 ? "#FFFFFF" : "#16202A"
  end

  def ordinal_voeu(n)
    n == 1 ? "1er vœu" : "#{n}e vœu"
  end

  def svg_tag(name)
    file_path = "#{Rails.root}/app/assets/images/#{name}.svg"
    if File.exists?(file_path)
       File.read(file_path).html_safe
    else
      '(not found)'
    end
  end

  def render_turbo_stream_flash_messages
    turbo_stream.prepend "flash", partial: "shared/flashes"
  end

  def active_course
    Course.where(ticket_activation: true).last
  end

  def default_course
    Course.find_by(id: session[:course_id]) || 
    active_course ||
    Course.find_by(position: 1)
  end
end
