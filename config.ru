require 'sinatra/base'
require './app'

# load all the server files
root_dir = File.dirname(__FILE__)
%w{helpers models controllers}.each do |type|
  Dir["#{root_dir}/server/#{type}/*.rb"].each do |file|
    require file
  end
end

# mount controllers as part of the overall rack config
map('/api/meta'){ run StatusCheckController }
map('/'){ run ViewController }
