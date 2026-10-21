module User::Traveler
  extend ActiveSupport::Concern

  DAILY_GOALS = [ 2, 3, 5, 8 ].freeze

  included do
    with_options on: :traveler do
      validates :name, presence: true, length: { maximum: 20 }
      validates :daily_goal_km, inclusion: { in: DAILY_GOALS }
    end
  end

  def traveler?
    name.present?
  end
end
