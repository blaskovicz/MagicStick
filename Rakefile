require 'rubocop/rake_task'

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
end
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = [
    'app.rb',
    'server/**/*.rb',
    'spec/**/*.rb',
    'Rakefile',
    'config.ru',
  ]
  # only show the files with failures
  # task.formatters = ['files']
  # don't abort rake on failure
  # task.fail_on_error = true
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
task :default => ['rubocop', 'test:test']
