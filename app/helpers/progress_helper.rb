module ProgressHelper
  def segmented_progress(fraction, segments: 10, color: :gold)
    fraction = fraction.to_f.clamp(0, 1)
    filled = (fraction * segments).floor

    tag.div class: "progress-segmented progress-segmented--#{color}", role: "progressbar",
      aria: { valuenow: (fraction * 100).round, valuemin: 0, valuemax: 100 } do
      safe_join(segments.times.map { |index| progress_segment(filled: index < filled) })
    end
  end

  private
    def progress_segment(filled:)
      tag.span class: [ "progress-segmented__segment", ("progress-segmented__segment--filled" if filled) ]
    end
end
