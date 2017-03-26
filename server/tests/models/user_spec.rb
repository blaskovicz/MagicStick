require_relative '../spec_helper'

describe 'User' do
  context 'validations' do
    it 'should set and check reasonable defaults' do
      user = User.new
      expect(user.username).to be_nil
      expect(user).not_to be_valid
      expect(user.errors[:username]).not_to be_nil
      expect(user.errors[:password]).not_to be_nil
      expect(user.errors[:email]).not_to be_nil
      expect(user.errors[:name]).not_to be_nil
    end

    it 'can be passed' do
      user = User.new(
        username: 'user-spec-test-user',
        password: 'hunter12',
        email: 'user-spec-test-dude@someweb.org',
        name: 'some dude'
      )
      expect(user).to be_valid
      user.save
      expect(user.id).not_to be_nil
      expect(user.user_identities.count).to eq(0)
    end
  end

  context 'password' do
    user = User.new(
      username: 'user-spec-test-user2',
      password: 'hunter12',
      email: 'user-spec-test-dude2@someweb.org',
      name: 'some dude2'
    )
    user.save
    it 'can be checked' do
      expect(user.password).not_to eq('hunter12') # encrypted
      expect(user.password_matches?('hunter12')).to eq(true)
      expect(user.password_matches?('hunter123')).to eq(false)
      expect(user.password_matches?('something else')).to eq(false)
    end
    it 'can be generated' do
      pass = {}
      20.times do
        next_pass = User.generate_password
        expect(next_pass.length).to eq(20)
        expect(pass).not_to have_key(next_pass)
        pass[next_pass] = true
      end
    end
    it 'can be changed' do
      user.plaintext_password = 'bobbehtables'
      expect(user.password).not_to eq('bobbehtables') # encrypted
      user.save
      user.reload
      expect(user.password).not_to eq('bobbehtables') # encrypted
      expect(user.password_matches?('hunter12')).to eq(false)
      expect(user.password_matches?('hunter123')).to eq(false)
      expect(user.password_matches?('something else')).to eq(false)
      expect(user.password_matches?('bobbehtables')).to eq(true)
    end
  end
end
