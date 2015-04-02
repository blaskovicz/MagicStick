class ViewController < ApplicationController
  get '/' do
    send_file "public/index.html"
  end
end
