require 'sequel'
require 'logger'
Sequel::Model.plugin :json_serializer
Sequel::Model.plugin :timestamps, :update_on_create => true

$db_url = ENV["DATABASE_URL"] || case ENV["RACK_ENV"]
when "production"
  "postgres://localhost/magicstick"
when "test"
  "sqlite://test.db"
else
  "sqlite://magicstick.db"
end
$DB = Sequel.connect($db_url)
$DB.loggers << Logger.new($stdout)
