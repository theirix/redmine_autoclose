require 'redmine'
require "#{File.dirname(__FILE__)}/lib/redmine_autoclose"

Redmine::Plugin.register :redmine_autoclose do
  name 'Redmine Autoclose plugin'
  author 'Eugene Seliverstov'
  author_url 'https://omniverse.ru'
  description 'Plugin to close issues automatically.'
  version '0.2.0'
  url 'https://github.com/theirix/redmine_autoclose'
  requires_redmine version_or_higher: '4.0.0'

  settings :default => {
    'autoclose_user' => '',
    'autoclose_projects' => '*',
    'autoclose_interval' => RedmineAutoclose::Config::DEFAULT_INTERVAL,
    'autoclose_note' => 'Issue is closed because it was resolved for a while.',
    'autoclose_resolved_status_ids' => RedmineAutoclose::Config::source_status_ids,
    'autoclose_closed_status_id' => RedmineAutoclose::Config::target_status_id,
    'autoclosed_active' => '0',
    'autoclose_project_names' => '0',
    'autoclose_tracker_ids' => ['']
  },
  :partial => 'settings/autoclose_settings'
end

if Gem::Version.new(Rails.version) > Gem::Version.new('6.0')
  Rails.application.config.after_initialize do
    RedmineAutoclose::Migrate.new.migrate_settings
  end
else
  ActiveSupport::Reloader.to_prepare do
    RedmineAutoclose::Migrate.new.migrate_settings
  end
end
