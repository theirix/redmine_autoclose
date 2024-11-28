RedmineApp::Application.routes.draw do
  match 'sys/autoclose_issues_preview', to: 'sys#autoclose_issues_preview', via: [:get, :post]
  match 'sys/autoclose_issues', to: 'sys#autoclose_issues', via: [:get, :post]
end
