namespace :autoclose do

  desc <<-END_DESC
Find affected issues and update them
  END_DESC
  task :autoclose => :environment do
    RedmineAutoclose::Autoclose.autoclose()
  end

  desc <<-END_DESC
Find affected issues and preview them without updating
  END_DESC
  task :preview => :environment do
    RedmineAutoclose::Autoclose.preview()
  end
end
