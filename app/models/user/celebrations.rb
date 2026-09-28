module User::Celebrations
  extend ActiveSupport::Concern

  included do
    has_many :celebrations, dependent: :destroy
  end

  def pending_celebration_keys
    journey.achievement_keys - celebrations.pluck(:key)
  end

  def next_celebration_key
    pending_celebration_keys.first
  end

  def celebrate(key)
    celebrations.find_or_create_by!(key: key)
  end

  def forget_unreached_celebrations
    celebrations.where.not(key: journey.achievement_keys).delete_all
  end
end
