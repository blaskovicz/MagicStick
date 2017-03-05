require_relative 'spec_helper'
require_relative '../server/controllers/auth'
require_relative '../server/helpers/slack'
require_relative '../server/helpers/auth'
require_relative '../server/helpers/request'
require_relative '../server/helpers/link'

describe 'Authentication' do
  def app
    AuthController
  end

  context 'unauthenticated' do
    it 'should permit account creation' do
      last_test = User.select[username: 'unit-test-account']
      last_test.delete if last_test
      post '/users', user: {
        username: 'unit-test-account',
        password: 'unit-test-password',
        passwordConfirmation: 'unit-test-password',
        name: 'Unit Test',
        email: 'unit-test-email@example.com'
      }
      expect(last_response.status).to equal(201)
      expect(JSON.parse(last_response.body)).to have_key('id')
    end
  end

  context 'authenticated' do
    it 'should permit profile update' do
      authorize 'unit-test-account', 'unit-test-password'
      post '/me', user: {
        name: 'Unit Test',
        email: 'unit-test-email@example.com',
        catchphrase: 'catchphrase'
      }
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to have_key('id')

      get '/me'
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to include('catchphrase' => 'catchphrase')

      get '/me/slack'
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to include('in_slack' => false)
    end

    it 'should permit password update' do
      authorize 'unit-test-account', 'unit-test-password'
      post '/me', user: {
        name: 'Unit Tester',
        email: 'unit-test-email@example.com',
        passwordCurrent: 'unit-test-password',
        password: 'unit-test-new-password',
        passwordConfirmation: 'unit-test-new-password'
      }
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to have_key('id')
    end

    def verify_user_search_response(_body)
      response = JSON.parse(last_response.body)
      expect(response).to have_key('users')
      expect(response['users'].size).to be(1)
      expect(response['users'][0]).to include('username' => 'unit-test-account')
      expect(response['users'][0]).to include('name' => 'Unit Tester')
    end

    it 'should filter by username insensitive' do
      authorize 'unit-test-account', 'unit-test-new-password'
      get '/users', limitted: true,
                    matching: 'Account'
      verify_user_search_response(last_response.body)
    end

    it 'should filter by name insensitive' do
      authorize 'unit-test-account', 'unit-test-new-password'
      get '/users', limitted: true,
                    matching: 'tester'
      verify_user_search_response(last_response.body)
    end

    it 'should filter by email exact match' do
      authorize 'unit-test-account', 'unit-test-new-password'
      get '/users',         limitted: true,
                            matching: 'unit-test-email@example.co'
      response = JSON.parse(last_response.body)
      expect(response).to have_key('users')
      expect(response['users'].size).to be(0)
      get '/users', limitted: true,
                    matching: 'unit-test-email@example.com'
      verify_user_search_response(last_response.body)
    end
  end
end
