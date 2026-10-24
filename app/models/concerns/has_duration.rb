module HasDuration
  extend ActiveSupport::Concern

  MAX_DURATION_S = 24.hours.to_i
  DURATION_PARTS = %i[ hours minutes seconds ]

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

  # O formulário manda horas, minutos e segundos em caixas separadas, pra 1:31 não virar dúvida.
  DURATION_PARTS.each do |part|
    define_method(:"duration_#{part}") do
      @duration_parts ? @duration_parts[part] : duration_split[part]
    end

    define_method(:"duration_#{part}=") do |value|
      @duration_text = nil
      @duration_parts = DURATION_PARTS.to_h { [ it, public_send(:"duration_#{it}").to_s ] }.merge(part => value.to_s.strip)
      self.duration_s = parse_duration_parts(@duration_parts)
      @duration_parts = nil if duration_s || @duration_parts.values.all?(&:blank?)
    end
  end

  private
    # Minutos sempre aparecem; horas e segundos só quando não são zero.
    def duration_split
      return {} unless duration_s

      hours, rest = duration_s.divmod(3600)
      minutes, seconds = rest.divmod(60)
      { hours: hours.nonzero?, minutes: minutes, seconds: seconds.nonzero? }
    end

    def parse_duration_parts(parts)
      return if parts.values.all?(&:blank?) || parts.values.any? { it.present? && !it.match?(/\A\d+\z/) }

      hours, minutes, seconds = parts.values_at(*DURATION_PARTS).map(&:to_i)
      total = hours * 3600 + minutes * 60 + seconds
      total if minutes < 60 && seconds < 60 && total.between?(1, MAX_DURATION_S)
    end

    def parse_duration(text)
      seconds =
        if text.blank?
          return nil
        elsif text.match?(/\A\d+\z/)
          text.to_i * 60
        elsif (match = text.match(/\A(?:(\d+)[:.,])?(\d{1,2})[:.,](\d{2})\z/)) && match[2].to_i < 60 && match[3].to_i < 60
          match[1].to_i * 3600 + match[2].to_i * 60 + match[3].to_i
        end

      seconds&.between?(1, MAX_DURATION_S) ? seconds : :invalid
    end

    def duration_readable
      errors.add(:duration, "não parece um tempo, use 38:51") if @duration_text
      errors.add(:duration, "confira o tempo: minutos e segundos vão até 59") if @duration_parts
    end
end
