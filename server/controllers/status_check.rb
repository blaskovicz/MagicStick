class StatusCheckController < ApplicationController
  get '/status' do
    'SUCCESS'
  end
  get '/version' do
    json version: VERSION
  end
end
