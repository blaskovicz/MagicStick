class UserController < ApplicationController
  helpers do
    def find_user!
      username = params[:username]
      user = User.first(username: username)
      json_halt 404, "User #{username} couldn't be found" if user.nil?
      user
    end
  end
  get '/:username/slack' do
    { in_slack: in_slack?(find_user!) }.to_json
  end

  get '/:username' do
    find_user!.to_json(only: User.public_attrs)
  end
end
