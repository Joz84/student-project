class UserSkillStatusPolicy < ApplicationPolicy
  def update?
    user.teacher? || record.user == user
  end
end
