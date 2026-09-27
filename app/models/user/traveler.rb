module User::Traveler
  extend ActiveSupport::Concern

  AVATARS = %w[ tropeiro romeira peregrino exploradora ].freeze
  DAILY_GOALS = [ 2, 3, 5, 8 ].freeze

  included do
    with_options on: :traveler do
      validates :name, presence: true, length: { maximum: 20 }
      validates :avatar, inclusion: { in: AVATARS }
      validates :daily_goal_km, inclusion: { in: DAILY_GOALS }
    end
  end

  def traveler?
    name.present?
  end
end
