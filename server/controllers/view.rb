class ViewController < ApplicationController
  get '/' do
    content_type 'text/html'
    send_file File.expand_path('index.html', settings.public_folder)
  end
end
