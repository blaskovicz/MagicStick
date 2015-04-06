require 'sinatra/base'
require 'sequel'
require 'rack/parser'
require_relative 'db/init'
require_relative 'app'
# load all the server files
root_dir = File.dirname(__FILE__)
%w{helpers models controllers}.each do |type|
  Dir["#{root_dir}/server/{*/,}#{type}/*.rb"].each do |file|
    require file
  end
end
# for some reason this was the only place I could register the helper
# with the controller; i'm sure there is a better way TODO
ApplicationController.helpers Auth
use Rack::Parser, :content_types => {
  'application/json' => Proc.new { |body| ::MultiJson.decode body }
}

# mount controllers as part of the overall rack config
map('/'){ run ViewController }
map('/api/meta'){ run StatusCheckController }
map('/api/auth'){ run AuthController }
map('/api/match'){ run MatchController }
