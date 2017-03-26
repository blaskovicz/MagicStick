require 'rack/test'
require 'rspec'
require 'coveralls'
require 'jwt'

Coveralls.wear!

require_relative '../../app'

ENV['SLACK_WEBHOOK_URL'] = 'http://localhost:12345/cool'
ENV['SECRET'] = 'test secret'
ENV['HMAC_SECRET'] = 'hmac test secret'
ENV['AUTH0_CLIENT_SECRET'] = 'auth0-test secret'

module RSpecMixin
  include Rack::Test::Methods
end

RSpec.configure { |c| c.include RSpecMixin }

def clear_deliveries
  Mail::TestMailer.deliveries.clear
end

def delivery_count
  Mail::TestMailer.deliveries.count
end

def deliveries
  Mail::TestMailer.deliveries.map(&:to).flatten
end

def email_deliveries
  Mail::TestMailer.deliveries
end

def last_response_json
  JSON.parse(last_response.body)
end

def sample_auth0_jwt(payload:)
  JWT.encode(payload, ENV['AUTH0_CLIENT_SECRET'], 'HS256')
end

def sample_auth0_payload
  iat = Time.now.to_i - 10_000
  exp = Time.now.to_i + 2_439
  {
    'email' => 'zach-attach@magic-stick.herokuapp.com',
    'email_verified' => true,
    'name' => 'Zach Ery',
    'given_name' => 'Zach',
    'family_name' => 'Ery',
    'iss' => 'https://magic-stick-app.auth0.com/',
    'sub' => 'facebook|12567',
    'aud' => 'some-audience',
    'exp' => exp,
    'iat' => iat
  }
end
