class User::TrainingLog
  attr_reader :walks, :stair_sessions

  def initialize(user)
    @walks = user.walks.reload.to_a
    @stair_sessions = user.stair_sessions.reload.to_a
    @walks_by_date = walks.group_by(&:walked_on)
    @stair_sessions_by_date = stair_sessions.group_by(&:climbed_on)
  end

  def dates
    @dates ||= (@walks_by_date.keys | @stair_sessions_by_date.keys).sort
  end

  def walks_on(date) = @walks_by_date.fetch(date, [])
  def stair_sessions_on(date) = @stair_sessions_by_date.fetch(date, [])
  def km_on(date) = walks_on(date).sum(BigDecimal(0), &:km)

  def climbed_m = stair_sessions.sum(BigDecimal(0), &:climb_m)

  def entries_newest_first
    (walks + stair_sessions).sort_by { [ entry_date(it), it.created_at ] }.reverse
  end

  private
    def entry_date(entry)
      entry.is_a?(Walk) ? entry.walked_on : entry.climbed_on
    end
end
