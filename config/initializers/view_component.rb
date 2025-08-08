require "view_component"
require "view_component/engine"

# ViewComponent configuration
Rails.application.config.view_component = ActiveSupport::OrderedOptions.new if Rails.application.config.view_component.nil?
Rails.application.config.view_component.generate ||= ActiveSupport::OrderedOptions.new
Rails.application.config.view_component.generate.sidecar = false

Rails.application.config.to_prepare do
  # Ensure components are loaded
  Dir[Rails.root.join("app/components/**/*.rb")].each { |f| require_dependency f }
end