require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/config_file'
require 'slack-notifier'
require 'pony'
require 'dotenv'
require 'redcarpet'
Dotenv.load

require_relative 'db/init'
# common controller for other controllers to inherit from.
# routes should not be defined here since this controller
# is effectively "mounted" at serveral places in the rack
# app (meaning routes defined here would be unintentially
# available in other random places).
# only common config and setup should be defined here
class ApplicationController < Sinatra::Base
  use Rack::Logger
  register Sinatra::ConfigFile
  @version = '0.3.0'
  config_file 'config.yml'
  configure do
    enable :sessions
    enable :logging
    set :method_override, false
  end
  ::MarkdownService = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
  Pony.options = {
    from: 'noreply@magic-stick.herokuapp.com',
    via: (ENV['RACK_ENV'] == 'production' ? :smtp : :test),
    via_options: {
      address: 'smtp.sendgrid.net',
      port: '587',
      domain: 'heroku.com',
      user_name: ENV['SENDGRID_USERNAME'],
      password: ENV['SENDGRID_PASSWORD'],
      authentication: :plain,
      enable_starttls_auto: true
    }
  }
  before do
    content_type 'application/json'
  end
end

# load all server helpers and files
root_dir = File.dirname(__FILE__)
%w(helpers models controllers).each do |type|
  Dir["#{root_dir}/server/{*/,}#{type}/*.rb"].each do |file|
    require file
  end
end
# for some reason this was the only place I could register the helper
# with the controller; i'm sure there is a better way TODO
ApplicationController.helpers Slack, Request, Auth, Link, Email
