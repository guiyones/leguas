module WorkoutHelper
  def pace(km, duration_s)
    if duration_s && km.to_f > 0
      seconds = (duration_s / km.to_f).round
      "#{seconds / 60}'#{(seconds % 60).to_s.rjust(2, "0")}\"/km"
    end
  end

  def speed(km, duration_s)
    if duration_s && duration_s > 0
      "#{(km.to_f * 3600 / duration_s).round(1).to_s.tr(".", ",")} km/h"
    end
  end

  def duration_text(duration_s)
    hours, rest = duration_s.divmod(3600)
    minutes, seconds = rest.divmod(60)

    if hours > 0
      format("%d:%02d:%02d", hours, minutes, seconds)
    else
      format("%d:%02d", minutes, seconds)
    end
  end
end
