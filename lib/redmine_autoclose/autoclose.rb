module RedmineAutoclose
  class Autoclose
    def self.when_issue_resolved(issue, status_ids)
      issue.journals.reverse_each do |j|
        status_change = j.new_value_for('status_id')
        return j.created_on if status_change && status_ids.include?(status_change.to_i)
      end
      nil
    end

    def self.log(use_logger, message)
      if use_logger && Rails.logger.info?
        Rails.logger.info(message)
      else
        $stderr.puts(message)
      end
    end

    def self.enumerate_issues(config, use_logger)
      statuses_resolved = config.resolved_statuses
      status_ids = statuses_resolved.map(&:id)
      projects_scope = config.active ? Project.active : Project
      if config.projects == ['*']
        projects = projects_scope.all
      else
        patterns = config.projects.map { |p| p.strip.gsub('*', '%') }
        field = config.project_names ? 'projects.name' : 'projects.identifier'
        sql_conditions = patterns.map { |_| "#{field} LIKE ?" }.join(' OR ')
        projects = projects_scope.where(sql_conditions, *patterns)
      end

      tracker_ids = config.trackers.map(&:id)
      projects.each do |project|
        project.issues.where(status_id: status_ids).each do |issue|
          next if tracker_ids.present? && !tracker_ids.include?(issue.tracker.id)
          when_resolved = when_issue_resolved(issue, status_ids)
          yield [issue, when_resolved] if when_resolved && when_resolved < config.interval_time
        end
      end
    end

    def self.preview(use_logger: false)
      config = RedmineAutoclose::Config.new
      enumerate_issues(config, use_logger) do |issue, when_resolved|
        log(use_logger, "Preview issue \##{issue.id} : #{issue.tracker.name} : #{issue.project.name} : (#{issue.subject}), " \
          "status '#{issue.status.name}', " \
          "with text '#{config.note.split('\\n').first.strip}...', " \
          "resolved #{when_resolved}")
      end
    end

    def self.autoclose(use_logger: false)
      config = RedmineAutoclose::Config.new
      status_closed = config.closed_status
      Mailer.with_synched_deliveries do
        enumerate_issues(config, use_logger) do |issue, _|
          log(use_logger, "Autoclosing issue \##{issue.id} : #{issue.tracker.name} : #{issue.project.name} : (#{issue.subject})")
          issue.with_lock do
            journal = issue.init_journal(config.user, config.note)
            raise 'Error creating journal' unless journal

            issue.status = status_closed
            issue.save(validate: false)
          end
        end
      end
    end
  end
end
