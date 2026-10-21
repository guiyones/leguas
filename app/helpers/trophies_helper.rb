module TrophiesHelper
  # Centros dos encaixes em art/trophies/vento_austral.svg, na ordem das fases.
  SLOT_CENTERS = [ [ 62, 190 ], [ 120, 190 ], [ 178, 190 ], [ 62, 226 ], [ 120, 226 ], [ 178, 226 ] ].freeze
  SLOT_RADIUS = 15

  def trophy_slot_state(journey, phase)
    case journey.phase_status(phase)
    when :completed then :filled
    when :current, :boss then :current
    else :empty
    end
  end

  def trophy_short_date(date)
    l date, format: :short
  end
end
