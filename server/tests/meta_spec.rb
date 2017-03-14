require_relative 'spec_helper'
require_relative '../controllers/status_check'

describe 'Meta' do
  def app
    StatusCheckController
  end

  it 'should respond to status check' do
    get '/status'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('SUCCESS')
  end

  it 'should show version info' do
    get '/version'
    expect(last_response.status).to eq(200)
    body = JSON.parse last_response.body
    expect(body).to have_key('version')
    expect(body['version']).not_to be_nil
  end
end
