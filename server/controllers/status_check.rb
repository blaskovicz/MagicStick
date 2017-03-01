class StatusCheckController < ApplicationController
  get '/status' do
    'SUCCESS'
  end
  get '/version' do
    json version: @version
  end
end
