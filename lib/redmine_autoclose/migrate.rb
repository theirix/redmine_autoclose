module RedmineAutoclose
  class Migrate
    def logger
      Rails.logger if Rails.logger.info?
    end

    def migrate_settings
      return if migration_done?

      resolved_status_ids = migrate_resolved_statuses
      closed_status_id = migrate_closed_status
      tracker_ids = migrate_trackers

      # Save all settings at once
      save_settings(resolved_status_ids, closed_status_id, tracker_ids)
    end

    private

    def migration_done?
      Setting.plugin_redmine_autoclose['autoclose_resolved_status_ids'].present? &&
        Setting.plugin_redmine_autoclose['autoclose_closed_status_id'].present? &&
        Setting.plugin_redmine_autoclose['autoclose_tracker_ids'].present?
    end

    def migrate_resolved_statuses
      resolved_status_names = fetch_setting_names('autoclose_resolved_statuses', 'autoclose_resolved_status') \
        || RedmineAutoclose::Config::DEFAULT_SOURCE_STATUS
      resolved_status_ids = map_names_to_ids(resolved_status_names, IssueStatus)

      if resolved_status_ids.any?
        log_migration("autoclose_resolved_statuses", resolved_status_ids)
      else
        logger.info("No resolved statuses found to migrate.")
      end

      resolved_status_ids.any? ? resolved_status_ids : RedmineAutoclose::Config::source_status_ids
    end

    def migrate_closed_status
      closed_status_name = Setting.plugin_redmine_autoclose['autoclose_closed_status'] \
        || RedmineAutoclose::Config::DEFAULT_TARGET_STATUS
      return unless closed_status_name.present?

      closed_status = IssueStatus.find_by(name: closed_status_name)
      if closed_status
        logger.info("Migrated autoclose_closed_status from name '#{closed_status_name}' to ID #{closed_status.id}")
        closed_status.id
      else
        logger.info("Closed status '#{closed_status_name}' not found.")
        RedmineAutoclose::Config::target_status_id
      end
    end

    def migrate_trackers
      tracker_names = fetch_setting_names('autoclose_trackers')
      tracker_ids = map_names_to_ids(tracker_names, Tracker)

      if tracker_ids.any?
        log_migration("autoclose_trackers", tracker_ids)
      else
        logger.info("No trackers found to migrate.")
      end

      tracker_ids
    end

    def fetch_setting_names(*keys)
      keys.flat_map { |key| Setting.plugin_redmine_autoclose[key] }.compact.uniq.tap do |names|
        names.replace(names.join(',').split(',').map(&:strip)) if names.is_a?(String)
      end
    end

    def map_names_to_ids(names, model)
      names.map { |name| model.find_by(name: name)&.id }.compact
    end

    def log_migration(setting_name, ids)
      logger.info("Migrated #{setting_name} to IDs: #{ids.join(', ')}") if ids.present?
    end

    def save_settings(resolved_status_ids, closed_status_id, tracker_ids)
      current_settings = Setting.plugin_redmine_autoclose || {}

      current_settings['autoclose_resolved_status_ids'] = resolved_status_ids if resolved_status_ids.present?
      current_settings['autoclose_closed_status_id'] = closed_status_id if closed_status_id.present?
      current_settings['autoclose_tracker_ids'] = tracker_ids if tracker_ids.present?

      # Persist settings to the database
      Setting.plugin_redmine_autoclose = current_settings
    end
  end
end
