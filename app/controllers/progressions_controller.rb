class ProgressionsController < ApplicationController
  def index
    @team = Team.find(params[:team_id])
    authorize @team, :show?
    @users = policy_scope(User).where(team: @team).kept
    @referential = @team.project.batch.referentials.find_by(active: true)
    @skill_blocks = @referential.skill_blocks.includes(:skills).order(:position)
    @meetings = @team.meetings.includes(presences: :user).order(date: :desc)
    @skill_scores = @users.index_by(&:id).transform_values(&:skill_scores)
    totals = @skill_scores.values.map { |s| s[:validated].values.sum + s[:finalized].values.sum + s[:in_progress].values.sum }
    @max_score = totals.max&.nonzero? || 1.0
    @team_validated_weeks = @skill_scores.values.sum { |s| s[:validated].values.sum }
    @skills_by_id = @skill_blocks.flat_map(&:skills).index_by(&:id)
    skill_ids = @skills_by_id.keys
    user_ids = @users.map(&:id)
    statuses = UserSkillStatus.where(user_id: user_ids, skill_id: skill_ids)
    @skill_statuses = statuses.each_with_object({}) do |s, h|
      h[[s.user_id, s.skill_id]] = s
    end
  end
end
