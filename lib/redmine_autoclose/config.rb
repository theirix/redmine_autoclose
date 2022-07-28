module RedmineAutoclose
  class Config
    DEFAULT_INTERVAL = 30

    def logger
      Rails.logger if Rails.logger.info?
    end

    def user
      unless @user
        user_email = Setting.plugin_redmine_autoclose['autoclose_user']
        if user_email.blank?
          @user = User.where(:admin => true).first
        else
          @user = User.find_by_mail(user_email)
          raise 'Cannot find autoclose user ' + user_email unless @user
        end
        logger.info("redmine_autoclose: using autoclose user #{@user.mail}") if logger
      end
      @user
    end

    def interval_time
      unless @interval_time
        @interval_time = (Setting.plugin_redmine_autoclose['autoclose_interval'] or DEFAULT_INTERVAL).to_i.days.ago
        logger.info("redmine_autoclose: using interval #{@interval_time}") if logger
      end
      @interval_time
    end

    def note
      unless @note
        @note = Setting.plugin_redmine_autoclose['autoclose_note']
        logger.info("redmine_autoclose: using note #{@note}") if logger
      end
      @note
    end

    def projects
      unless @projects
        @projects = (Setting.plugin_redmine_autoclose['autoclose_projects'] or '')
                    .split(',').map(&:strip) - ['']
        logger.info("redmine_autoclose: projects #{@projects.join(',')}") if logger
      end
      @projects
    end

    def active
      @active ||= (Setting.plugin_redmine_autoclose['autoclose_active'] || '0') == '1'
    end

    def resolved_statuses
      names = Setting.plugin_redmine_autoclose['autoclose_resolved_statuses'] || \
              [Setting.plugin_redmine_autoclose['autoclose_resolved_status']]
      @resolved_statuses ||= names.map { |name| IssueStatus.find_by_name(name) }
    end

    def closed_status
      @closed_status ||= IssueStatus.find_by_name(Setting.plugin_redmine_autoclose['autoclose_closed_status'] || 'Closed')
    end
  end
end
