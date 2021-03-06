class ViewController < ApplicationController
  PREFIX = 'SINATRA_PUBLIC_ENV_'.freeze
  get '/' do
    # eg: SINATRA_PUBLIC_ENV_RAYGUN_API_KEY=bar would
    # be set to RAYGUN_API_KEY=bar in @env
    @env = ENV.each_with_object({}) do |field, o|
      next unless field.first.start_with? PREFIX
      o[field.first.sub(PREFIX, '')] = field.last
    end
    @env[:MAGIC_STICK_VERSION] = VERSION
    @env[:RACK_ENV] = ENV['RACK_ENV']
    content_type :html
    erb :index
  end
end
