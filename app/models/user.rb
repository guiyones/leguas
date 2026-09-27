class User < ApplicationRecord
  include Traveler

  has_many :auth_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :walks, dependent: :destroy
  has_many :missions, dependent: :destroy

  normalizes :email_address, with: -> { it.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def journey(world: World.current)
    Journey.new(self, world: world)
  end
end
