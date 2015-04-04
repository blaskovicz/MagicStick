require 'sequel'
Sequel::Model.plugin :json_serializer
$db_url = ENV["DATABASE_URL"] || (
  ENV["RACK_ENV"] == "production" ?
  "postgres://localhost/magicstick" :
  "sqlite://magicstick.db"
)
$DB = Sequel.connect($db_url)

