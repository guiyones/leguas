module PhasesHelper
  def tip_of_the_day(region)
    if region.tips.any?
      region.tips[Date.current.yday % region.tips.size]
    end
  end
end
