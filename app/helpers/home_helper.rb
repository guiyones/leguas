module HomeHelper
  def tip_of_the_day(region)
    region.tips[Date.current.yday % region.tips.size]
  end
end
