namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "./db/init"
    Sequel.extension :migration
    puts "Using database #{$db_url}"
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run($DB, "db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run($DB, "db/migrations")
    end
  end
  task :seed, [:type] do |t, args|
    require "./db/init"
    if args[:type] == "roles"
      [
        {:name => "admin", :description => "site admin"},
        {:name => "moderator", :description => "site helper"}
      ].each do |role|
        $DB[:roles].insert(role)
      end
    else
      puts "please provide a recognized type (eg: [roles])"
    end
  end
end
