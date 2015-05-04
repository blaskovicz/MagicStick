class UserController < ApplicationController
  get '/:username' do
    username = params[:username]
    user = User.first(:username => username)
    json_halt 404, "User #{username} couldn't be found" if user.nil?
    user.to_json(:only => User.public_attrs)
  end
end
