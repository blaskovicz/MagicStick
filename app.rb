require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/config_file'
require 'slack-notifier'
require 'dotenv'
Dotenv.load
# common controller for other controllers to inherit from.
# routes should not be defined here since this controller
# is effectively "mounted" at serveral places in the rack
# app (meaning routes defined here would be unintentially
# available in other random places).
# only common config and setup should be defined here
class ApplicationController < Sinatra::Base
  use Rack::Logger
  register Sinatra::ConfigFile
  @@version = "0.2.0"
  config_file 'config.yml'
  configure do
    enable :sessions
    enable :logging
    set :method_override, false
  end
  before do
    content_type "application/json"
  end
  helpers do
    def logger
      request.logger
    end
  end
end
