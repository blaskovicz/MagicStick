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
namespace :test do
  desc "Configure test environment"
  task :configure do
    ENV['RACK_ENV'] = 'test'
  end

  desc "Execute tests"
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ["--color", "-f documentation"]
    t.pattern = Dir.glob("spec/**/*_spec.rb")
  end

  desc "Prepare environment and run test suite"
  task :test => ['test:configure', 'db:migrate', 'test:spec'] do
  end
end
task :default => ['test:test']
