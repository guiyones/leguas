class Walk < ApplicationRecord
  include Backdatable

  DAILY_LIMIT_KM = 100

  belongs_to :user

  validates :walked_on, presence: true
  validates :km, numericality: { greater_than: 0 }
  backdatable :walked_on
  validates :load_kg, numericality: { greater_than: 0, less_than_or_equal_to: 40 }, allow_nil: true
  validate :daily_limit_respected

  after_save :ensure_mission
  after_commit :forget_unreached_celebrations

  scope :newest_first, -> { order(walked_on: :desc, created_at: :desc) }

  def km=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  def load_kg=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  private
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
      user.forget_unreached_celebrations
    end
end
