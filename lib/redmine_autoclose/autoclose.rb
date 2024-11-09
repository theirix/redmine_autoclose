module RedmineAutoclose
  class Autoclose
    def self.when_issue_resolved(issue, statuses_resolved)
      statuses_resolved_ids = statuses_resolved.map(&:id)
      issue.journals.reverse_each do |j|
        status_change = j.new_value_for('status_id')
        return j.created_on if status_change && statuses_resolved_ids.include?(status_change.to_i)
      end
      nil
    end

    def self.enumerate_issues(config)
      statuses_resolved = config.resolved_statuses
      projects_scope = config.active ? Project.active : Project
      if config.projects == ['*'] # rubocop:disable Style/ConditionalAssignment
        projects = projects_scope.all
      else
        projects = projects_scope.where('projects.identifier in (?)', config.projects)
      end
      if config.trackers.empty?
        tracker_ids = Tracker.pluck(:id)
      else
        tracker_ids = config.trackers.map(&:id)
      end
      $stderr.puts("Searching among #{projects.size} projects with tracker ids: #{tracker_ids}")
      projects.each do |project|
        project.issues.where(status_id: statuses_resolved, tracker_id: tracker_ids).each do |issue|
          when_resolved = when_issue_resolved(issue, statuses_resolved)
          yield [issue, when_resolved] if when_resolved && when_resolved < config.interval_time
        end
      end
    end

    def self.preview
      config = RedmineAutoclose::Config.new
      enumerate_issues(config) do |issue, when_resolved|
        $stderr.puts("Preview issue \##{issue.id} (#{issue.subject}), " \
          "status '#{issue.status.name}', " \
          "with text '#{config.note.split('\\n').first.strip}...', " \
          "resolved #{when_resolved}")
      end
    end

    def self.autoclose
      config = RedmineAutoclose::Config.new
      status_closed = config.closed_status
      Mailer.with_synched_deliveries do
        enumerate_issues(config) do |issue, _|
          $stderr.puts "Autoclosing issue \##{issue.id} (#{issue.subject})"
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
