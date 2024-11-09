Redmine::Plugin.register :redmine_autoclose do
  name 'Redmine Autoclose plugin'
  author 'Eugene Seliverstov'
  author_url 'https://omniverse.ru'
  description 'Autoclose plugin'
  version '0.0.12'
  url 'http://github.com/theirix/redmine_autoclose'

  require File.dirname(__FILE__) + '/lib/redmine_autoclose'

  settings :default => {
    'autoclose_user' => '',
    'autoclose_projects' => '*',
    'autoclose_interval' => RedmineAutoclose::Config::DEFAULT_INTERVAL,
    'autoclose_note' => 'Issue is closed because it was resolved for a while.',
    'autoclose_resolved_status' => 'Resolved',
    'autoclose_resolved_statuses' => ['Resolved'],
    'autoclose_closed_status' => 'Closed',
    'autoclosed_active' => '0',
    'autoclose_trackers' => []
  },
  :partial => 'settings/autoclose_settings'
end
