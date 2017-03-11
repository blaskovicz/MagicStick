require 'rack/test'
require 'rspec'
require 'sequel'
require 'coveralls'
Coveralls.wear!

require_relative '../app'

ENV['SECRET'] = 'test secret'
ENV['HMAC_SECRET'] = 'hmac test secret'

module RSpecMixin
  include Rack::Test::Methods
end

RSpec.configure { |c| c.include RSpecMixin }
