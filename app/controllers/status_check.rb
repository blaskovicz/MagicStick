class App < Sinatra::Base
  get '/api/status' do
    "SUCCESS"
  end
  get '/api/version' do
    json :version => @@version
  end
end
