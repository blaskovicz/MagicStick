require 'base64'
require_relative '../spec_helper'
require_relative '../../helpers/auth'
require_relative '../../helpers/logger'

describe 'Auth Helper' do
  include Auth
  include MagicLogger

  attr_reader :slack_dummy, :email_dummy

  def invite_to_slack(*args)
    @slack_dummy.invite_to_slack(*args)
  end

  def email_welcome(*args)
    @email_dummy.email_welcome(*args)
  end

  before(:each) do
    @slack_dummy = double('slack-dummy')
    @email_dummy = double('email-dummy')
  end

  def with_secret
    ENV['SECRET'] = 'very secret'
    yield
    ENV.delete 'SECRET'
  end

  context 'cipher' do
    it 'functions should exist' do
      expect(respond_to?('encrypt')).to be true
      expect(respond_to?('decrypt')).to be true
    end
    it 'should have basic error handling' do
      ENV.delete 'SECRET'
      expect { encrypt('foo') }.to raise_error
      expect { decrypt('bar', 'baz') }.to raise_error
    end
    it 'can encrypt and decrypt' do
      with_secret do
        target_phrase = "What's up unit test!"
        encrypted, iv = encrypt target_phrase
        expect(encrypted).not_to eq(target_phrase)
        expect(iv).not_to eq(target_phrase)
        expect(encrypted.length).to be > target_phrase.length

        decrypted = decrypt(encrypted, iv)
        expect(decrypted).to eq(target_phrase)
      end
    end
  end
  context 'jwt' do
    it 'can generate and veryify magic-stick issuer' do
      user = User.new(username: 'sample-jwt-user', password: 'test-password', email: 'no-reply@gmail.com', name: 'same user')
      user.save
      expect(user).not_to be_nil
      token = nil
      found_user = nil
      expect do
        token = encode_jwt(user)
      end.not_to raise_error
      expect(token).not_to be_nil
      expect do
        found_user = decode_jwt_user(token)
      end.not_to raise_error
      expect(found_user).to be_instance_of(User)
      expect(found_user.id).to eq(user.id)
      dt = JWT.decode token, hmac_secret, true, algorithm: 'HS256'
      expect(dt[0]).to have_key('user')
    end
    it 'can veryify auth0 issuer if user dne' do
      expect(@email_dummy).to receive(:email_welcome)
      expect(@slack_dummy).to receive(:invite_to_slack)
      expect(User.find(email: sample_auth0_payload['email'])).to be_nil
      token = nil
      user = nil
      expect do
        token = sample_auth0_jwt payload: sample_auth0_payload
      end.not_to raise_error
      expect(token).not_to be_nil
      expect do
        user = decode_jwt_user(token)
      end.not_to raise_error
      expect(user).to be_instance_of(User)
      expect(user.username).not_to be_nil
      expect(user.password).not_to be_nil
      expect(user.email).to eq(sample_auth0_payload['email'])
      expect(user.user_identities.count).to eq(1)
      ident = user.user_identities.first
      expect(ident.user_id).to eq(user.id)
      expect(ident.provider_id).to eq(sample_auth0_payload['sub'])
      expect(ident.user.id).to eq(user.id)
    end
    it 'can veryify auth0 issuer if user exists, identity does not' do
      user = User.new(username: 'sample-jwt-user33', password: 'test-password', email: 'some-crazy-outage@gmail.com', name: 'same user')
      user.save
      expect(user).not_to be_nil
      expect(User.find(email: user.email)).not_to be_nil
      expect(user.user_identities.count).to eq(0)
      user2 = nil
      payload = sample_auth0_payload.merge(
        'email' => user.email,
        'sub' => 'google-oauth2|99382'
      )
      expect do
        token = sample_auth0_jwt(
          payload: payload
        )
        user2 = decode_jwt_user(token)
      end.not_to raise_error
      expect(user2).to be_instance_of(User)
      expect(user2.email)
      expect(user2.id).to eq(user.id)
      expect(user2.user_identities.count).to eq(1)
      ident = user2.user_identities.first
      expect(ident.provider_id).to eq(payload['sub'])
      expect(ident.user_id).to eq(user.id)
      expect(ident.user.id).to eq(user.id)
    end
    it 'can veryify auth0 issuer if user exists, identity does' do
      user = User.new(username: 'sample-jwt-user5', password: 'test-password5', email: 'howareyou@foo.com', name: 'some other user')
      user.save
      expect(user).not_to be_nil
      ident = UserIdentity.new(provider_id: 'google-oauth2|8675309')
      user.add_user_identity ident
      user.reload
      expect(user.user_identities.count).to eq(1)
      user2 = nil
      expect do
        token = sample_auth0_jwt payload: sample_auth0_payload.merge(
          'email' => 'random-unrelated-email@gmail.com',
          'sub' => ident.provider_id
        )
        user2 = decode_jwt_user(token)
      end.not_to raise_error
      expect(user2).to be_instance_of(User)
      expect(user2.id).to eq(user.id)
      expect(user.email).to eq(user2.email)
      expect(user2.user_identities.count).to eq(1)
    end
  end
end
