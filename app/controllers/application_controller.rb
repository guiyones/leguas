class ApplicationController < ActionController::Base
  include Onboarding, Authentication

  allow_browser versions: :modern
  stale_when_importmap_changes
end
