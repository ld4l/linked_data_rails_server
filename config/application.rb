require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)


module LinkedDataRailsServer
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths << Rails.root.join('lib')

    require 'linked_data_rails_server'

    db_config = Rails.configuration.database_configuration
    host      = db_config[Rails.env]["host"]
    database  = db_config[Rails.env]["database"]
    username  = db_config[Rails.env]["username"]
    password  = db_config[Rails.env]["password"]
    $files = ::Ld4lBrowserData::Utilities::FileSystems::MySqlZipFS.new(host: host, username: username, password: password, database: database)
  end
end
