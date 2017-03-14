require 'rubocop/rake_task'

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |_t, args|
    require_relative 'db/init'
    Sequel.extension :migration
    puts "Using database #{::DATABASE_URL}"
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(::Database, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(::Database, 'db/migrations')
    end
  end
end
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = [
    'db/init.rb',
    'app.rb',
    'server/**/*.rb',
    'Rakefile',
    'config.ru'
  ]
  task.options = [
    '--display-cop-names',
    '--color'
  ]
  # only show the files with failures
  # task.formatters = ['files']
  # don't abort rake on failure
  # task.fail_on_error = true
end
namespace :test do
  desc 'Configure test environment'
  task :configure do
    ENV['RACK_ENV'] = 'test'
  end

  desc 'Execute tests'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = ['--color', '-f documentation']
    t.pattern = Dir.glob('server/tests/**/*_spec.rb')
  end

  desc 'Prepare environment and run test suite'
  task test: ['test:configure', 'db:migrate', 'test:spec'] do
  end
end
task default: ['rubocop', 'test:test']
