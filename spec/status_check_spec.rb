require_relative 'spec_helper'
require_relative '../server/controllers/status_check'

describe "Status Check" do
  def app() StatusCheckController end

  it "should respond with success" do
    get '/status'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('SUCCESS')
  end
end
