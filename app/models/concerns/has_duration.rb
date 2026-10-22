module HasDuration
  extend ActiveSupport::Concern

  MAX_DURATION_S = 24.hours.to_i

  included do
    validate :duration_readable
  end

  class_methods do
    def format_duration(seconds)
      hours, rest = seconds.divmod(3600)
      minutes, secs = rest.divmod(60)

      if hours > 0
        format("%d:%02d:%02d", hours, minutes, secs)
      else
        format("%d:%02d", minutes, secs)
      end
    end
  end

  def duration
    @duration_text || (duration_s && self.class.format_duration(duration_s))
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
      seconds =
        if text.blank?
          return nil
        elsif text.match?(/\A\d+\z/)
          text.to_i * 60
        elsif (match = text.match(/\A(?:(\d+):)?(\d{1,2}):(\d{2})\z/)) && match[2].to_i < 60 && match[3].to_i < 60
          match[1].to_i * 3600 + match[2].to_i * 60 + match[3].to_i
        end

      seconds&.between?(1, MAX_DURATION_S) ? seconds : :invalid
    end

    def duration_readable
      errors.add(:duration, "não parece um tempo, use 38:51") if @duration_text
    end
end
