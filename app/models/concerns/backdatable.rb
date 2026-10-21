module Backdatable
  extend ActiveSupport::Concern

  RETROACTIVE_DAYS = 7

  class_methods do
    def backdatable(attribute)
      validate :"#{attribute}_within_window"

      define_method :"#{attribute}_min" do
        if new_record?
          Date.current - RETROACTIVE_DAYS
        else
          [ attribute_was(attribute) || self[attribute], Date.current - RETROACTIVE_DAYS ].min
        end
      end

      define_method :"#{attribute}_within_window" do
        value = self[attribute]
        if value && attribute_changed?(attribute) && !value.between?(Date.current - RETROACTIVE_DAYS, Date.current)
          errors.add(attribute, "precisa ser de hoje ou dos últimos #{RETROACTIVE_DAYS} dias")
        end
      end
      private :"#{attribute}_within_window"
    end
  end
end
