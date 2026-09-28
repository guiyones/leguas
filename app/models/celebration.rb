class Celebration < ApplicationRecord
  belongs_to :user

  validates :key, presence: true
end
