class User < ApplicationRecord
  include Celebrations, Traveler

  has_many :auth_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :walks, dependent: :destroy
  has_many :missions, dependent: :destroy
  has_many :stair_sessions, dependent: :destroy

  normalizes :email_address, with: -> { it.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :stair_steps, numericality: { only_integer: true, in: 1..1000 }, allow_nil: true

  after_update_commit :forget_unreached_celebrations, if: :saved_change_to_stair_steps?

  def journey(world: World.current)
    Journey.new(self, world: world)
  end

  def training_log
    @training_log ||= TrainingLog.new(self)
  end

  def forget_training_log
    @training_log = nil
  end

  def reload(*)
    forget_training_log
    super
  end
end
