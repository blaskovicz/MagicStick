require 'sequel'
Sequel::Model.plugin :json_serializer
Sequel::Model.plugin :timestamps, :update_on_create => true

$db_url = ENV["DATABASE_URL"]

case ENV["RACK_ENV"]
when "production"
  $db_url ||= "postgres://localhost/magicstick"
when "test"
  $db_url ||= "sqlite://test.db"
else
  $db_url ||= "sqlite://magicstick.db"
end

$DB = Sequel.connect($db_url)
