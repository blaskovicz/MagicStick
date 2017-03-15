require_relative 'app'
require 'rack/parser'
require 'raygun4ruby'

use Rack::Parser, content_types: {
  'application/json' => proc { |body| ::MultiJson.decode body }
}

Raygun.setup do |config|
  config.api_key = ENV['RAYGUN_APIKEY']
end

use Raygun::Middleware::RackExceptionInterceptor

# mount controllers as part of the overall rack config
map('/') { run ViewController }
map('/api/meta') { run StatusCheckController }
map('/api/auth') { run AuthController }
map('/api/users') { run UserController }
map('/api/match') { run MatchController }
