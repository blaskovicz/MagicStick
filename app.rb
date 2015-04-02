require 'sinatra/base'
require 'sinatra/json'
# common controller for other controllers to inherit from.
# routes should not be defined here since this controller
# is effectively "mounted" at serveral places in the rack
# app (meaning routes defined here would be unintentially
# available in other random places).
# only common config and setup should be defined here
class ApplicationController < Sinatra::Base
  @@version = "0.1.0"
  configure do
    enable :sessions
    set :logging, true
  end
end
