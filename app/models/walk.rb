class Walk < ApplicationRecord
  include Backdatable

  DAILY_LIMIT_KM = 100

  belongs_to :user

  validates :walked_on, presence: true
  validates :km, numericality: { greater_than: 0 }
  backdatable :walked_on
  validates :load_kg, numericality: { greater_than: 0, less_than_or_equal_to: 40 }, allow_nil: true
  validates :elevation_gain_m, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validate :daily_limit_respected
  validate :duration_readable

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

  def duration
    @duration_text || (duration_s && format_duration(duration_s))
  end

  def duration=(text)
    @duration_text = nil
    seconds = parse_duration(text.to_s.strip)

    if seconds == :invalid
      @duration_text = text
      self.duration_s = nil
    else
      self.duration_s = seconds
    end
  end

  private
    def parse_duration(text)
      if text.blank?
        nil
      elsif text.match?(/\A\d+\z/)
        text.to_i * 60
      elsif (match = text.match(/\A(?:(\d+):)?(\d{1,2}):(\d{2})\z/)) && match[2].to_i < 60 && match[3].to_i < 60
        match[1].to_i * 3600 + match[2].to_i * 60 + match[3].to_i
      else
        :invalid
      end
    end

    def format_duration(seconds)
      hours, rest = seconds.divmod(3600)
      minutes, secs = rest.divmod(60)

      if hours > 0
        format("%d:%02d:%02d", hours, minutes, secs)
      else
        format("%d:%02d", minutes, secs)
      end
    end

    def duration_readable
      errors.add(:duration, "não parece um tempo, use 38:51") if @duration_text
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
