require 'rack/test'
require 'rspec'
require 'coveralls'
Coveralls.wear!

require_relative '../../app'

ENV['SLACK_WEBHOOK_URL'] = 'http://localhost:12345/cool'
ENV['SECRET'] = 'test secret'
ENV['HMAC_SECRET'] = 'hmac test secret'

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
