class User < ApplicationRecord
  has_many :auth_tokens, dependent: :destroy
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: -> { it.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
