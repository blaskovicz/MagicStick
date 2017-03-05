require 'sinatra/base'
require 'sequel'
require 'rack/parser'
require_relative 'app'

use Rack::Parser, content_types: {
  'application/json' => proc { |body| ::MultiJson.decode body }
}

# mount controllers as part of the overall rack config
map('/') { run ViewController }
map('/api/meta') { run StatusCheckController }
map('/api/auth') { run AuthController }
map('/api/users') { run UserController }
map('/api/match') { run MatchController }
