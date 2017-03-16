require_relative '../spec_helper'
require_relative '../../controllers/user'
require_relative '../../helpers/slack'
require_relative '../../helpers/auth'
require_relative '../../helpers/request'
require_relative '../../helpers/link'

describe 'User' do
  def app
    UserController
  end

  context 'info' do
    it 'should permit access to public properties by username' do
      expected = User.first
      get "/#{User.first.username}"
      expect(last_response.status).to equal(200)
      got = JSON.parse last_response.body
      %w(password email).each do |private_field|
        expect(got).not_to include(private_field)
      end
      expect(got).to include('username' => expected.username)
    end

    it 'should permit access to slack status' do
      get "/#{User.first.username}/slack"
      expect(last_response.status).to equal(200)
      got = JSON.parse last_response.body
      expect(got).to include('in_slack' => false)
    end
  end
end
