require 'rack/test'
require 'rspec'

require_relative '../app'

module RSpecMixin
  include Rack::Test::Methods
end

RSpec.configure { |c| c.include RSpecMixin }
