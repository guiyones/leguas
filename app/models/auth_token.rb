class AuthToken < ApplicationRecord
  EXPIRATION = 15.minutes

  belongs_to :user

  validates_presence_of :code, :expires_at

  before_validation :generate_code, on: :create

  scope :valid, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def self.lookup(email_address:, code:)
    if email_address.present? && code.present?
      if user = User.find_by(email_address: email_address)
        valid.find_by(user: user, code: code)
      end
    end
  end

  def deliver_later
    AuthTokenMailer.otp(self).deliver_later
  end

  def use!
    update!(used_at: Time.current)
    user.auth_tokens.excluding(self).destroy_all
  end

  private
    def generate_code
      self.code = SixDigitCode.generate
    end
end
