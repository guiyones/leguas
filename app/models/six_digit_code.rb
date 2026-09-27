module SixDigitCode
  def self.generate = format("%06d", SecureRandom.random_number(900_000) + 100_000)
end
