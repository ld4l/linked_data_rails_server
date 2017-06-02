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

    $files = ::Ld4lBrowserData::Utilities::FileSystems::MySqlZipFS.new(:username => 'ld4luser', :password => 'ld4lpass')

  end
end
