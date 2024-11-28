# Redmine Autoclose Plugin

The plugin automatically closes issues that have been resolved but not closed for a specified
interval.

Compatible with Redmine versions: 5.x, 4.x.

## Configuration

The plugin provides a settings page where you can specify:
- **Check interval**: Number of days after which an issue is treated as stalled.
- **Comment text**: The comment posted to the issue.
- **User**: The user who posts the notification (Admin by default).
- **Projects**: A comma-separated list of project identifiers included in the check, or `*` for all projects.
- **Resolved statuses**: One or more statuses interpreted as resolved.
- **Closed status**: The status used as a closed status.
- **Trackers**: Selection of trackers used for an issue. If the list is empty, all trackers are
  valid.

## Launching

There are two ways to initial an auto close, rake task and REST API.

### The plugin provides two rake tasks:

Call `bundle exec rake <task name>` form Redmine root dir:

Tasks:

1. **`autoclose:autoclose`**  
   Finds affected issues and updates them.

2. **`autoclose:preview`**  
   Finds affected issues and prints them to `STDERR` without making any changes.

### The plugin can be executed via REST API as follows:

Endpoints (GET and POST):

1. **`sys/autoclose_issues`**  
   Finds affected issues and updates them.

2. **`sys/autoclose_issues_preview`**  
   Finds affected issues and prints them to `STDERR` without making any changes.

Note: The API Key is used from the default `sys/fetch_changesets` API.
Web service for repositories must by activated in the Administration menu (Administration -
Settings - Repositories - Enable WS for repository management) and the generated API key (referred
to "your service key" in the following documentation) will have to be used by the caller.

### Crontab Entry

To automate the process, there are two options for creating a crontab:

#### Via rake task

```bash
0 1 * * * cd REDMINE_ROOT && bundle exec rake autoclose:autoclose RAILS_ENV=production
```

#### Via REST call

```bash
0 1 * * * curl -s -X POST -d "key=${REDMINE_API_KEY}" "${REDMINE_URL}/sys/autoclose_issues"
```
Replace or set `REDMINE_URL` and `REDMINE_API_KEY` accordingly.
