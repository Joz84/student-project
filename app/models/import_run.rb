# Une exécution de l'import d'emploi du temps, réussie ou non.
class ImportRun < ApplicationRecord
  scope :recentes, -> { order(started_at: :desc) }

  def duree = finished_at && (finished_at - started_at).round(1)
  def echec? = error.present?

  def resume
    return "échec : #{error.lines.first.to_s.strip}" if echec?
    "#{created_count} créées, #{updated_count} mises à jour, #{unchanged_count} inchangées" \
      "#{", #{deleted_count} supprimées" if deleted_count.to_i.positive?}" \
      "#{", #{kept_count} conservées" if kept_count.to_i.positive?}"
  end

  def self.derniere_reussite = where(error: nil).recentes.first

  # Vrai si l'import a tourné dans les dernières 36 heures : au-delà, une
  # tâche quotidienne a manifestement été manquée.
  def self.a_jour?(maintenant = Time.current)
    d = derniere_reussite
    d.present? && d.started_at > maintenant - 36.hours
  end
end
