class AuthController < ApplicationController
  before %r{^/users/+([^/]+)} do |user_id|
    @user = User[id: user_id]
    halt 404, "User #{user_id} couldn't be found" if @user.nil?
  end
  get '/roles' do
    requires_role! :admin
    json :roles => Role.all
  end
  get '/users' do
    requires_role! :admin
    json :users => User.all
  end
  get '/users/:user_id' do
    requires_role! :admin
    json :user => @user
  end
  delete '/users/:user_id' do
    requires_role! :admin
    @user.delete
    status 204
  end
  get '/users/:user_id/roles' do
    requires_role! :admin
    json :roles => @user.roles
  end
  post '/users/:user_id/roles/:role_id' do |user_id, role_id|
    requires_role! :admin
    role = find_role! role_id
    unless $DB[:users_roles].where(user_id: user_id, role_id: role_id).first.nil?
      halt 409, "User #{user_id} already in role #{role_id}"
    end
    @user.add_role role
    status 204
  end
  delete '/users/:user_id/roles/:role_id' do |user_id, role_id|
    requires_role! :admin
    @user.remove_role find_role!(role_id)
    status 204
  end
  post '/users' do
    user_param_presence!
    params[:user].delete 'passwordConfirmation'
    # is there a better way to do this? TODO
    new_user = User.new params[:user]
    halt 400, json(:errors => new_user.errors) unless new_user.valid?
    new_user.save
    status 201
    json :id => new_user.id
  end
  get '/me' do
    requires_login!
    principal.to_json
  end
  helpers do
    def find_role!(role_id, status = 400)
      role = Role[id: role_id]
      halt status, "Role #{role_id} not found" if role.nil?
      role
    end
    def user_param_presence!
      halt 400, "No user object found in request payload" if params[:user].nil?
    end
  end
end
