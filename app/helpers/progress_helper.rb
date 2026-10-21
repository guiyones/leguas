module ProgressHelper
  def progress_bar(fraction, color: :gold)
    percent = (fraction.to_f.clamp(0, 1) * 100).round

    tag.div class: "progress progress--#{color}", role: "progressbar",
      aria: { valuenow: percent, valuemin: 0, valuemax: 100 } do
      tag.span class: "progress__fill", style: "width: #{percent}%"
    end
  end
end
