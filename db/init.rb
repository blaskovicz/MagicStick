require 'sequel'
require_relative '../server/helpers/logger'
Sequel::Model.plugin :json_serializer
Sequel::Model.plugin :timestamps, update_on_create: true
::DATABASE_URL = (ENV['DATABASE_URL'] || case ENV['RACK_ENV']
                                         when 'production'
                                           'postgres://localhost/magicstick'
                                         when 'test'
                                           'sqlite://test.db'
                                         else
                                           'sqlite://magicstick.db'
                                         end).freeze
::Database = Sequel.connect(DATABASE_URL)
Database.loggers << Object.new.extend(MagicLogger).logger
