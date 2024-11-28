module RedmineAutoclose
  class Config
    DEFAULT_INTERVAL = 30
    DEFAULT_SOURCE_STATUS = 'Resolved'
    DEFAULT_TARGET_STATUS = 'Closed'

    def self.source_status_ids
      status = IssueStatus.find_by(name: DEFAULT_SOURCE_STATUS)
      status ? [status.id] : ['']
    end

    def self.target_status_id
      status = IssueStatus.find_by(name: DEFAULT_TARGET_STATUS)
      status ? status.id : ''
    end

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
          raise "Cannot find autoclose user #{user_email}" unless @user
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

    def project_names
      @project_names ||= (Setting.plugin_redmine_autoclose['autoclose_project_names'] || '0') == '1'
    end

    def resolved_statuses
      status_ids = Setting.plugin_redmine_autoclose['autoclose_resolved_status_ids'] || []
      status_ids = status_ids.is_a?(Array) ? status_ids : status_ids.split(',')
      status_ids = status_ids.map(&:to_s).map(&:strip)
      valid_statuses = IssueStatus.where(id: status_ids).collect
      @resolved_statuses ||= valid_statuses.presence || []
    end

    def closed_status
      closed_status_id = Setting.plugin_redmine_autoclose['autoclose_closed_status_id'] \
        || IssueStatus.find_by(name: DEFAULT_TARGET_STATUS)&.id
      @closed_status ||= IssueStatus.find_by(id: closed_status_id)
    end

    def trackers
      tracker_ids = Setting.plugin_redmine_autoclose['autoclose_tracker_ids'] || []
      tracker_ids = tracker_ids.is_a?(Array) ? tracker_ids : tracker_ids.split(',')
      tracker_ids = tracker_ids.map(&:to_s).map(&:strip)
      valid_trackers = Tracker.where(id: tracker_ids).collect
      @trackers ||= valid_trackers.presence || []
    end
  end
end
