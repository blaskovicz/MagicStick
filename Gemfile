source 'http://rubygems.org'
ruby '2.1.5'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'unicorn'
gem 'sequel'
gem 'rack-parser', require: 'rack/parser'
gem 'rake'
gem 'rspec'
gem 'sass'
gem 'slack-notifier'
gem 'dotenv'
gem 'pony'
gem 'redcarpet'
gem 'rubocop', require: false # outside developement group for Rakefile
group :production do
  gem 'pg'
end
group :development do
  gem 'sqlite3'
  gem 'shotgun'
  gem 'coveralls', require: false
end
