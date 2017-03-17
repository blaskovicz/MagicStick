require 'base64'
require_relative '../spec_helper'
require_relative '../../controllers/auth'
require_relative '../../helpers/slack'
require_relative '../../helpers/auth'
require_relative '../../helpers/request'
require_relative '../../helpers/link'

describe 'Authentication' do
  def app
    AuthController
  end

  def email_deliveries
    Mail::TestMailer.deliveries
  end

  context 'unauthenticated' do
    it 'should permit account creation' do
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

    it 'should allow resetting a password' do
      expect(email_deliveries.count).to eq(0)
      post '/forgot-password', {}
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)).to include('errors' => 'No user object found in request payload')
      expect(email_deliveries.count).to eq(0)

      post '/forgot-password', user: { username: 'unit-test-account', email: 'unit-test-email@example.com-wrong' }
      expect(last_response.status).to eq(204)
      expect(email_deliveries.count).to eq(0)

      post '/forgot-password', user: { username: 'unit-test-account', email: 'unit-test-email@example.com' }
      expect(last_response.status).to eq(204)
      expect(email_deliveries.count).to eq(1)
      # nutty logic to grab the link from the encoded email.
      %r{(?<magic_link>/password-reset/.+?)\.}m =~ email_deliveries.last.html_part.to_s
      expect(magic_link).not_to be_nil
      magic_link.gsub!("=\r\n", '')
      parts = magic_link.split('/')
      expect(parts.length).to eq(4)
      token = parts[parts.length - 2]
      iv = parts.last

      post '/forgot-password', user: { token: token, iv: iv, password: 'new-password' }
      expect(last_response.status).to eq(204)
      expect(email_deliveries.count).to eq(2)

      user = User.find(username: 'unit-test-account')
      expect(user.password_matches?('new-password')).to eq(true)
      expect(user.password_matches?('unit-test-password')).to eq(false)

      # reset the password so we don't break tests below
      user.plaintext_password = 'unit-test-password'
      user.save
      expect(user.password_matches?('new-password')).to eq(false)
      expect(user.password_matches?('unit-test-password')).to eq(true)
    end
  end

  context 'authenticated' do
    it 'should generate a jwt upon login' do
      authorize 'unit-test-account', 'unit-test-password'
      post '/login', {}
      expect(last_response.status).to equal(200)
      expect(JSON.parse(last_response.body)).to have_key('token')

      authorize 'unit-test-account', 'wrong-pass'
      post '/login', {}
      expect(last_response.status).to equal(401)
      expect(JSON.parse(last_response.body)).not_to have_key('token')
      expect(JSON.parse(last_response.body)).to include('errors' => 'Insufficient credentials provided')
    end

    it 'should accept a valid jwt for api auth' do
      authorize 'unit-test-account', 'unit-test-password'
      post '/login', {}
      token = Base64.urlsafe_decode64(JSON.parse(last_response.body)['token'])

      authorize 'noone', 'noone'
      header('Authorization', "Bearer #{token.split('.').map { |p| p + '3' }.join('.')}")
      get '/me'
      expect(last_response.status).to equal(401)
      expect(JSON.parse(last_response.body)).not_to have_key('token')
      expect(JSON.parse(last_response.body)).to include('errors' => 'Insufficient credentials provided')

      sleep 1
      header('Authorization', "Bearer #{token}")
      get '/me'
      expect(last_response.status).to equal(200)
      body = JSON.parse(last_response.body)
      expect(body).to include('username' => 'unit-test-account')
      expect(body['last_login']).not_to be_nil
      expect(body['updated_at']).not_to be_nil
      expect(body['last_login']).not_to eq(body['updated_at'])
    end

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
