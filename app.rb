require 'sinatra/base'
require 'sinatra/json'
class App < Sinatra::Base
  @@version = "0.1.0"
  configure do
    enable :sessions
    set :logging, true
  end
end

# load all helpers, models and controllers into the current app
root_dir = File.dirname(__FILE__)
%w{helpers models controllers}.each do |type|
  Dir["#{root_dir}/app/#{type}/*.rb"].each do |file|
    require file
  end
end
