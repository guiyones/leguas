module Onboarding
  extend ActiveSupport::Concern

  included do
    before_action :require_traveler
  end

  class_methods do
    def allow_unnamed_traveler(**options)
      skip_before_action :require_traveler, **options
    end
  end

  private
    def require_traveler
      if Current.user && !Current.user.traveler?
        redirect_to new_traveler_path
      end
    end
end
