module RedmineAutoclose
  
  class Autoclose

    def self.when_issue_resolved issue, status_resolved
      issue.journals.reverse_each do |j|
        status_change = j.new_value_for('status_id')
        return j.created_on if status_change && status_change.to_i == status_resolved.id
      end
      nil
    end

    def self.enumerate_issues config
      status_resolved = IssueStatus.find_by_name('Resolved')
      Project.where('projects.identifier in (?)', config.projects).each do |project|
        project.issues.where(:status_id => status_resolved).each do |issue|
          when_resolved = when_issue_resolved(issue, status_resolved)
          yield [issue, when_resolved] if when_resolved && when_resolved < config.interval_time
        end
      end
    end

    def self.preview

      config = RedmineAutoclose::Config.new
      self.enumerate_issues(config) do |issue, when_resolved|
        STDERR.puts("Preview issue \##{issue.id} (#{issue.subject}), " +
          "status '#{issue.status.name}', " +
          "with text '#{config.note.split('\\n').first.strip}...', " +
          "resolved #{when_resolved}")
      end
    end

    def self.autoclose
      config = RedmineAutoclose::Config.new
      status_closed = IssueStatus.find_by_name('Closed')
      self.enumerate_issues(config) do |issue, _|
        STDERR.puts "Autoclosing issue \##{issue.id} (#{issue.subject})"
        journal = issue.init_journal(config.user, config.note)
        raise 'Error creating journal' unless journal
        issue.status = status_closed
        issue.save
      end
    end
  
  end
  
end
