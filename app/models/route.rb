class Route < ApplicationRecord
  include HasDuration

  belongs_to :user
  has_many :walks, dependent: :nullify
  has_one_attached :photo

  validates :name, presence: true, length: { maximum: 40 }
  validates :km, numericality: { greater_than: 0 }

  before_validation :drop_invalid_trace

  scope :by_distance, -> { order(:km, :name) }

  def km=(value)
    super(value.is_a?(String) ? value.tr(",", ".") : value)
  end

  private
    # Um trace ruim nunca bloqueia salvar a rota.
    def drop_invalid_trace
      self.trace = nil unless trace.nil? || Trace.valid?(trace)
    end
end
