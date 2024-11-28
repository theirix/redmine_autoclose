module RedmineAutoclose
  module Patches
    module Controllers
      module SysControllerPatch
        extend ActiveSupport::Concern

        included do
          prepend InstanceMethods
        end

        module InstanceMethods
          def autoclose_issues_preview
            begin
              RedmineAutoclose::Autoclose.preview(use_logger: true)
              head :ok # Return HTTP 200 OK if successful
            rescue StandardError => e
              Rails.logger.error("Error in autoclose_issues_preview: #{e.message}")
              head :internal_server_error # Return HTTP 500 Internal Server Error on exception
            end
          end

          def autoclose_issues
            begin
              RedmineAutoclose::Autoclose.autoclose(use_logger: true)
              head :ok # Return HTTP 200 OK if successful
            rescue StandardError => e
              Rails.logger.error("Error in autoclose_issues: #{e.message}")
              head :internal_server_error # Return HTTP 500 Internal Server Error on exception
            end
          end
        end
      end
    end
  end
end

unless SysController.included_modules.include?(RedmineAutoclose::Patches::Controllers::SysControllerPatch)
  SysController.send(:include, RedmineAutoclose::Patches::Controllers::SysControllerPatch)
end
