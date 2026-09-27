class Mission < ApplicationRecord
  XP = 20

  belongs_to :user

  scope :accomplished, -> {
    where(<<~SQL)
      missions.goal_km <= (
        SELECT COALESCE(SUM(walks.km), 0) FROM walks
        WHERE walks.user_id = missions.user_id AND walks.walked_on = missions.date
      )
    SQL
  }

  def walked_km
    user.walks.where(walked_on: date).sum(:km)
  end

  def accomplished?
    walked_km >= goal_km
  end
end
