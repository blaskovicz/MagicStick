require_relative 'spec_helper'
require_relative '../server/controllers/auth'

describe "Authentication" do
  def app() AuthController end

  before do
    User.select.delete
  end

  context "unauthenticated" do
    it "should permit account creation" do
      post '/users', {
        :user => {
          :username => 'unit-test-account',
          :password => 'unit-test-password',
          :passwordConfirmation => 'unit-test-password',
          :email => 'unit-test-email@example.com'
        }
      }
      expect(last_response.status).to equal(201)
      expect(JSON.parse(last_response.body)).to have_key("id")
    end
  end
end
