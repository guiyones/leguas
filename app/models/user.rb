class User < ApplicationRecord
  include Celebrations, Traveler

  has_many :auth_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :walks, dependent: :destroy
  has_many :routes, dependent: :destroy
  has_many :missions, dependent: :destroy
  has_many :stair_sessions, dependent: :destroy

  normalizes :email_address, with: -> { it.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :stair_steps, numericality: { only_integer: true, in: 1..1000 }, allow_nil: true
  validates :stair_steps, presence: { message: "não podem sumir depois que você registrou escada. A altura das suas subidas vem deles." },
    if: -> { stair_sessions.exists? }

  after_update_commit :forget_training_log, :forget_unreached_celebrations, if: :saved_change_to_stair_steps?

  # The journey in the current world is kept until the training log changes;
  # a journey in any other world is replayed on every call.
  def journey(world: nil)
    if world
      Journey.new(self, world: world)
    else
      current_journey
    end
  end

  def training_log
    @training_log ||= TrainingLog.new(self)
  end

  def forget_training_log
    @training_log = @journey = nil
  end

  def reload(*)
    forget_training_log
    super
  end

  private
    def current_journey
      unless @journey&.world.equal?(World.current)
        @journey = Journey.new(self, world: World.current)
      end

      @journey
    end
end
