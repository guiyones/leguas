module ProgressRedirect
  extend ActiveSupport::Concern

  private
    def redirect_after_progress(xp_before)
      redirect_to_celebration_or phase_path, notice: progress_notice(xp_before, Current.user.journey.xp)
    end

    def redirect_to_celebration_or(path, notice:)
      if Current.user.next_celebration_key
        redirect_to celebration_path, notice: notice
      else
        redirect_to path, notice: notice
      end
    end

    def progress_notice(xp_before, xp_after)
      level_before = User::Level.new(xp_before).number
      level_after = User::Level.new(xp_after).number

      if level_after > level_before
        "+#{xp_after - xp_before} XP · Nível #{level_after}!"
      else
        "+#{xp_after - xp_before} XP"
      end
    end
end
