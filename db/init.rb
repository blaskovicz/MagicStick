require 'sequel'
require 'logger'
Sequel::Model.plugin :json_serializer
Sequel::Model.plugin :timestamps, :update_on_create => true
$db_url = ENV["DATABASE_URL"] || (
  ENV["RACK_ENV"] == "production" ?
  "postgres://localhost/magicstick" :
  "sqlite://magicstick.db"
)
$DB = Sequel.connect($db_url)
$DB.loggers << Logger.new($stdout)
