require 'base64'
require_relative 'spec_helper'
require_relative '../helpers/auth'
require_relative '../helpers/logger'

describe 'Auth Helper' do
  include Auth
  include MagicLogger

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
    it 'can generate and veryify' do
      # TODO: cleanse test db between runs
      user = User.find(username: 'sample-jwt-user')
      if user.nil?
        user = User.new(username: 'sample-jwt-user', password: 'test-password', email: 'no-reply@gmail.com', name: 'same user')
        user.save
        expect(user).not_to be_nil
      end
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
  end
end
