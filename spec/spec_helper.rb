require 'rack/test'
require 'rspec'
require 'sequel'
require 'coveralls'
Coveralls.wear!

require_relative '../db/init'
require_relative '../app'

# TODO: Abstract this to avoid copy and paste from config.ru
root_dir = File.dirname(__FILE__) + '/..'
%w(helpers models controllers).each do |type|
  Dir["#{root_dir}/server/{*/,}#{type}/*.rb"].each do |file|
    require file
  end
end

module RSpecMixin
  include Rack::Test::Methods
end

RSpec.configure { |c| c.include RSpecMixin }
