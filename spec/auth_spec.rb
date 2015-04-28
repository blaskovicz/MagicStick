require_relative 'spec_helper'
require_relative '../server/controllers/auth'
require_relative '../server/helpers/auth'
require_relative '../server/helpers/request'

describe "Authentication" do
  AuthController.helpers Auth, Request
  def app() AuthController end

  context "unauthenticated" do
    it "should permit account creation" do
      last_test = User.select[:username => 'unit-test-account']
      last_test.delete if last_test
      post '/users', {
        :user => {
          :username => 'unit-test-account',
          :password => 'unit-test-password',
          :passwordConfirmation => 'unit-test-password',
          :name => 'Unit Test',
          :email => 'unit-test-email@example.com'
        }
      }
      expect(last_response.status).to equal(201)
      expect(JSON.parse(last_response.body)).to have_key("id")
    end
  end

  context "authenticated" do
    it "should permit profile update" do
      authorize 'unit-test-account', 'unit-test-password'
      post '/me', {
        :user => {
          :name => 'Unit Test',
          :email => 'unit-test-email@example.com',
          :catchphrase => 'catchphrase'
        }
      }
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to have_key("id")

      get '/me'
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to include("catchphrase" => "catchphrase")
    end

    it "should permit password update" do
      authorize 'unit-test-account', 'unit-test-password'
      post '/me', {
        :user => {
          :name => 'Unit Test',
          :email => 'unit-test-email@example.com',
          :passwordCurrent => 'unit-test-password',
          :password => 'unit-test-new-password',
          :passwordConfirmation => 'unit-test-new-password',
        }
      }
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to have_key("id")
    end
  end
end
