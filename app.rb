require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/config_file'
# common controller for other controllers to inherit from.
# routes should not be defined here since this controller
# is effectively "mounted" at serveral places in the rack
# app (meaning routes defined here would be unintentially
# available in other random places).
# only common config and setup should be defined here
class ApplicationController < Sinatra::Base
  register Sinatra::ConfigFile
  @@version = "0.1.0"
  config_file 'config.yml'
  configure do
    enable :sessions
    set :logging, true
    set :method_override, false
  end
  before do
    content_type "application/json"
  end
end
