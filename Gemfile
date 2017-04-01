source 'https://rubygems.org'
ruby '2.4.1'

gem 'sinatra', '~>1.4'
gem 'sinatra-contrib'
gem 'unicorn'
gem 'sequel', '~>4.21'
gem 'rack-parser', require: 'rack/parser'
gem 'rake'
gem 'rspec'
gem 'slack-notifier'
gem 'dotenv'
gem 'pony'
gem 'httparty'
gem 'redcarpet'
gem 'rubocop', require: false # outside developement group for Rakefile
gem 'jwt'
gem 'raygun4ruby'
group :production do
  gem 'pg'
end
group :development do
  gem 'puma'
  gem 'sqlite3'
  gem 'shotgun'
  gem 'coveralls', require: false
end
