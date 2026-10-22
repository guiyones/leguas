class Walk < ApplicationRecord
  include Backdatable, HasDuration

  DAILY_LIMIT_KM = 100
  MAX_STEPS = 200_000
  MAX_ELEVATION_M = 10_000

  belongs_to :user
  belongs_to :route, optional: true

  validates :walked_on, presence: true
  validates :km, numericality: { greater_than: 0 }
  backdatable :walked_on
  validates :load_kg, numericality: { greater_than: 0, less_than_or_equal_to: 40 }, allow_nil: true
  validates :elevation_gain_m, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_ELEVATION_M }, allow_nil: true
  validates :steps, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_STEPS }, allow_nil: true
  validate :daily_limit_respected
  validate :route_is_users_own

  after_save :ensure_mission
  after_commit :forget_unreached_celebrations

  def km=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  def load_kg=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  def steps=(value)
    super(value.is_a?(String) ? value.delete(".") : value)
  end

  private
    def route_is_users_own
      if route_id && route.nil?
        errors.add(:route, "não existe mais")
      elsif route && route.user_id != user_id
        errors.add(:route, "não é sua")
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
      user.missions.create_or_find_by!(date: walked_on) { it.goal_km = user.daily_goal_km }
    end

    def forget_unreached_celebrations
      user.forget_training_log
      user.forget_unreached_celebrations
    end
end
