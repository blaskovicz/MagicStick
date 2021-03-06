require 'base64'
require 'digest'
require_relative '../spec_helper'
require_relative '../../controllers/auth'
require_relative '../../helpers/slack'
require_relative '../../helpers/auth'
require_relative '../../helpers/request'
require_relative '../../helpers/link'

describe 'Authentication' do
  def verify_user_search_response(body)
    response = JSON.parse(body)
    expect(response).to have_key('users')
    expect(response['users'].size).to be(1)
    expect(response['users'][0]).to include('username' => 'unit-test-account')
    expect(response['users'][0]).to include('name' => 'Unit Tester')
  end

  def app
    AuthController
  end

  before(:all) do
    @role_admin = Role.find name: 'admin'
    raise 'no admin role' unless @role_admin
    @role_mod = Role.find name: 'moderator'
    raise 'no mod role' unless @role_mod
    @user_admin = User.new(
      username: 'an-admin-user',
      password: 'great-pass',
      email: 'auth-spec-admin-test@magic-stick.herokuapp.com',
      name: 'admin user dudeman'
    )
    raise 'failed to save user admin' unless @user_admin.save
    @user_admin.add_role @role_admin
  end

  before(:each) do
    clear_deliveries
    expect(email_deliveries.count).to eq(0)
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
      expect(email_deliveries.count).to eq(1)
    end

    it 'should allow resetting a password' do
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
    it 'should generate a magic-stick iss jwt upon login' do
      authorize 'unit-test-account', 'unit-test-password'
      post '/login', {}
      expect(last_response.status).to equal(200)
      parsed_body = JSON.parse(last_response.body)
      expect(parsed_body).to have_key('token')
      expect { Base64.urlsafe_decode64(parsed_body['token']) }.not_to raise_error

      authorize 'unit-test-account', 'wrong-pass'
      post '/login', {}
      expect(last_response.status).to equal(401)
      expect(JSON.parse(last_response.body)).not_to have_key('token')
      expect(JSON.parse(last_response.body)).to include('errors' => 'Insufficient credentials provided')
    end

    it 'should accept a valid magic-stick iss jwt for api auth' do
      authorize 'unit-test-account', 'unit-test-password'
      post '/login', {}
      expect(last_response.status).to eq(200)
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
      expect(body['user_identities']).to eq([])
    end

    it 'should accept an auth0 iss token' do
      token = sample_auth0_jwt(payload: sample_auth0_payload.merge('email' => 'unit-test-email@example.com', 'sub' => 'facebook|88888841213'))
      header('Authorization', "Bearer #{token}")
      2.times do
        get '/me'
        expect(last_response.status).to equal(200)
        body = JSON.parse(last_response.body)
        expect(body).to include('username' => 'unit-test-account')
        expect(body['last_login']).not_to be_nil
        expect(body['updated_at']).not_to be_nil
        expect(body['id']).not_to be_nil
        expect(body['last_login']).not_to eq(body['updated_at'])
        idents = body['user_identities']
        expect(idents.count).to eq(1)
        expect(idents.first['id']).not_to be_nil
        expect(idents.first['provider_id']).to eq('facebook|88888841213')
        expect(idents.first['user_id']).to eq(body['id'])
      end
    end

    it 'should auto-create an account from an auth0 iss token if necessary' do
      token = sample_auth0_jwt(payload: sample_auth0_payload.merge('email' => 'some-unique-email-1234@gmail.com', 'sub' => 'google-oauth2|123456789101112'))
      header('Authorization', "Bearer #{token}")
      2.times do
        get '/me'
        expect(last_response.status).to equal(200)
        body = JSON.parse(last_response.body)
        expect(body).to include('username' => 'google_user_123456789101112')
        expect(body['last_login']).not_to be_nil
        expect(body['updated_at']).not_to be_nil
        expect(body['id']).not_to be_nil
        expect(body['email']).to eq('some-unique-email-1234@gmail.com')
        idents = body['user_identities']
        expect(idents.count).to eq(1)
        expect(idents.first['id']).not_to be_nil
        expect(idents.first['provider_id']).to eq('google-oauth2|123456789101112')
        expect(idents.first['user_id']).to eq(body['id'])
      end
    end

    it 'should return a magic-stick iss token upon auth0 iss login' do
      token = sample_auth0_jwt(payload: sample_auth0_payload.merge('email' => 'unit-test-email@example.com', 'sub' => 'facebook|88888841213'))
      header('Authorization', "Bearer #{token}")
      post '/login', {}
      expect(last_response.status).to eq(200)
      token2 = nil
      expect do
        token2 = Base64.urlsafe_decode64(JSON.parse(last_response.body)['token'])
      end.not_to raise_error

      header('Authorization', "Bearer #{token2}")
      get '/me'
      expect(last_response.status).to equal(200)
      body = JSON.parse(last_response.body)
      expect(body).to include('username' => 'unit-test-account')
      expect(body['last_login']).not_to be_nil
      expect(body['updated_at']).not_to be_nil
      expect(body['id']).not_to be_nil
      expect(body['last_login']).not_to eq(body['updated_at'])
      idents = body['user_identities']
      expect(idents.count).to eq(1)
      expect(idents.first['id']).not_to be_nil
      expect(idents.first['provider_id']).to eq('facebook|88888841213')
      expect(idents.first['user_id']).to eq(body['id'])
    end

    it 'should allow linking a basic account to a provider' do
      authorize 'unit-test-account', 'unit-test-password'
      post '/me/identities', {}
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)).to include('errors' => 'No token found in request payload')

      post '/me/identities', token: 'hithere'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)).to include('errors' => 'Unable to link account to provider identity')

      token = Base64.urlsafe_encode64(sample_auth0_jwt(payload: sample_auth0_payload.merge('email' => 'crazy-train-email@somesiteexample.com', 'sub' => 'google-oauth2|deadbeef123')))
      post '/me/identities', token: token
      expect(last_response.status).to eq(204)

      post '/me/identities', token: token
      expect(last_response.status).to eq(409)
      expect(JSON.parse(last_response.body)).to include('errors' => 'Provider identity already linked to account')
    end

    it 'should allow removing a provider link from an account' do
      authorize 'unit-test-account', 'unit-test-password'
      get '/me'
      ids = JSON.parse(last_response.body)['user_identities']
      expect(ids.length).not_to eq(0)
      ident = ids.last

      2.times do
        delete "/me/identities/#{ident['id']}"
        expect(last_response.status).to eq(204)
      end

      get '/me'
      ids2 = JSON.parse(last_response.body)['user_identities']
      expect(ids2.map { |i| i['id'] }).not_to include(ident['id'])
      expect(ids2.map { |i| i['provider_id'] }).not_to include(ident['provider_id'])
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

      authorize '', ''
      get '/me/slack'
      expect(last_response.status).to equal(401)
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

    it 'should allow an admin to see roles' do
      authorize 'an-admin-user', 'great-pass'
      get '/roles'
      expect(last_response.status).to eq(200)
      b = JSON.parse(last_response.body)
      expect(b['roles']).to be_kind_of(Array)
      expect(b['roles'].length).not_to eq(0)
      expect(b['roles'][0]['name']).not_to be_empty
      expect(b['roles'][0]['description']).not_to be_empty
    end

    it 'should allow an admin direct lookup of a user' do
      authorize 'an-admin-user', 'great-pass'
      u = User.find(username: 'unit-test-account')
      expect(u).not_to be_nil
      get "/users/#{u.id}"
      expect(last_response.status).to eq(200)
      b = JSON.parse(last_response.body)
      expect(b['user']).to be_kind_of(Hash)
      expect(b['user']['email']).to eq(u.email)
      expect(b['user']['username']).to eq(u.username)
      expect(b['user']['name']).to eq(u.name)
      expect(b['user']['id']).to eq(u.id)
    end

    it 'should allow upload and view of an avatar' do
      # the user has no avatar set, make sure we redirect to gravatar
      u = User.find(username: 'unit-test-account')
      expect(u).not_to be_nil
      get "/users/#{u.id}/avatar"
      expect(last_response.status).to eq(302)
      expect(last_response.body).to be_empty
      expect(last_response.headers['Location']).to match(%r{^https://secure.gravatar.com})

      # user uploads an avatar
      authorize 'unit-test-account', 'unit-test-new-password'
      avatar_path = File.join(
        File.dirname(__FILE__), '..', '..', '..', 'public', 'img', 'magic-wand.jpeg'
      )
      local_digest = Digest::MD5.file(avatar_path).hexdigest
      file_size = File.stat(avatar_path).size
      post '/me/avatar', 'file' => Rack::Test::UploadedFile.new(avatar_path, 'image/jpeg')
      expect(last_response.body).to be_empty
      expect(last_response.status).to eq(204)

      # make sure anyone can see it successfully
      authorize '', ''
      get "/users/#{u.id}/avatar"
      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to eq('image/jpeg')
      remote_digest = Digest::MD5.new.update(last_response.body).hexdigest
      expect(remote_digest).to eq(local_digest)
      expect(last_response.headers['Content-Length'].to_i).to eq(file_size)
      expect(last_response.headers['Last-Modified']).not_to be_nil
      expect(last_response.headers['Cache-Control']).not_to be_nil
    end

    it 'should allow an admin to adjust user roles' do
      authorize 'an-admin-user', 'great-pass'
      u = User.find(username: 'unit-test-account')
      expect(u).not_to be_nil

      # we start with no roles
      get "/users/#{u.id}/roles"
      expect(last_response.status).to eq(200)
      b = JSON.parse(last_response.body)
      expect(b['roles']).to be_kind_of(Array)
      expect(b['roles'].length).to eq(0)

      # add the user to moderator role
      post "/users/#{u.id}/roles/#{@role_mod.id}"
      expect(last_response.status).to eq(204)

      # can't add them again
      post "/users/#{u.id}/roles/#{@role_mod.id}"
      expect(last_response.status).to eq(409)
      expect(JSON.parse(last_response.body)).to include('errors' => "User #{u.id} already in role #{@role_mod.id}")

      # make sure they were added
      get "/users/#{u.id}/roles"
      expect(last_response.status).to eq(200)
      b = JSON.parse(last_response.body)
      expect(b['roles']).to be_kind_of(Array)
      expect(b['roles'].length).to eq(1)
      expect(b['roles'][0]['name']).to eq(@role_mod.name)
      expect(b['roles'][0]['description']).to eq(@role_mod.description)

      # now remove them from the role
      2.times do
        delete "/users/#{u.id}/roles/#{@role_mod.id}"
        expect(last_response.status).to eq(204)
      end

      # make sure it's gone
      get "/users/#{u.id}/roles"
      expect(last_response.status).to eq(200)
      b = JSON.parse(last_response.body)
      expect(b['roles']).to be_kind_of(Array)
      expect(b['roles'].length).to eq(0)
    end
  end
end
