class StairSession < ApplicationRecord
  include Backdatable

  STEP_RISE_M = BigDecimal("0.17")
  DAILY_LIMIT = 500

  belongs_to :user

  backdatable :climbed_on

  validates :climbed_on, presence: true
  validates :climbs, numericality: { only_integer: true, greater_than: 0 }
  validates :load_kg, numericality: { greater_than: 0, less_than_or_equal_to: 40 }, allow_nil: true
  validate :user_has_stair_steps, :daily_limit_respected

  after_commit :forget_unreached_celebrations

  def load_kg=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  def climb_m
    climbs * user.stair_steps.to_i * STEP_RISE_M
  end

  private
    def forget_unreached_celebrations
      user.forget_training_log
      user.forget_unreached_celebrations
    end

    def user_has_stair_steps
      errors.add(:base, "Informe os degraus da sua escada no perfil antes de registrar subidas.") unless user&.stair_steps
    end

    def daily_limit_respected
      if climbs && climbed_on && climbs + climbs_already_that_day > DAILY_LIMIT
        errors.add(:climbs, "passa de #{DAILY_LIMIT} subidas no dia")
      end
    end

    def climbs_already_that_day
      user.stair_sessions.where(climbed_on: climbed_on).excluding(self).sum(:climbs)
    end
end
