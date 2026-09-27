class Walk < ApplicationRecord
  DAILY_LIMIT_KM = 100
  RETROACTIVE_DAYS = 7

  belongs_to :user

  validates :walked_on, presence: true
  validates :km, numericality: { greater_than: 0 }
  validate :walked_on_within_window, :daily_limit_respected

  after_save :ensure_mission

  scope :newest_first, -> { order(walked_on: :desc, created_at: :desc) }

  def km=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  private
    def walked_on_within_window
      if walked_on && walked_on_changed? && !walked_on.between?(Date.current - RETROACTIVE_DAYS, Date.current)
        errors.add(:walked_on, "precisa ser de hoje ou dos últimos #{RETROACTIVE_DAYS} dias")
      end
    end

    def daily_limit_respected
      if km && walked_on && km + km_already_walked_that_day > DAILY_LIMIT_KM
        errors.add(:km, "passa de #{DAILY_LIMIT_KM} km no dia. Essa distância parece exagerada, viajante.")
      end
    end

    def km_already_walked_that_day
      user.walks.where(walked_on: walked_on).excluding(self).sum(:km)
    end

    def ensure_mission
      user.missions.find_or_create_by!(date: walked_on) { it.goal_km = user.daily_goal_km }
    end
end
