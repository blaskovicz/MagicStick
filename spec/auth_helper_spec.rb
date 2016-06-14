require_relative 'spec_helper'
require_relative '../server/helpers/auth'

describe "Auth Helper" do
  include Auth
  def with_secret
    ENV['SECRET'] = 'very secret'
    yield
    ENV.delete 'SECRET'
  end
  context "cipher" do
    it "functions should exist" do
      expect(respond_to? 'encrypt').to be true
      expect(respond_to? 'decrypt').to be true
    end
    it "should have basic error handling" do
      ENV.delete 'SECRET'
      expect { encrypt("foo") }.to raise_error
      expect { decrypt("bar", "baz") }.to raise_error
    end
    it "can encrypt and decrypt" do
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
end
