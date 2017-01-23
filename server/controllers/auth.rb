require 'date'
require 'base64'
class AuthController < ApplicationController
  before %r{^/users/+([^/]+)} do |user_id|
    @user = User[id: user_id]
    json_halt 404, "User #{user_id} couldn't be found" if @user.nil?
  end
  get '/roles' do
    requires_role! :admin
    json :roles => Role.all
  end
  get '/users' do
    if params[:limitted]
      requires_login!
      params[:matching] ||= ""
      User.where(Sequel.expr(active: true) & (
          Sequel.ilike(:username, '%' + params[:matching] + '%') |
          Sequel.ilike(:name, '%' + params[:matching] + '%') |
          Sequel.ilike(:email, params[:matching])
        ))
        .to_json(root: true, :only => User.public_attrs)
    else
      requires_role! :admin
      User.to_json(root: true, exclude: :avatar)
    end
  end
  get '/users/:user_id' do
    requires_role! :admin
    json :user => @user
  end
  get '/users/:user_id/avatar' do
    content_type @user.avatar_content_type
    @user.avatar
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
      json_halt 409, "User #{user_id} already in role #{role_id}"
    end
    @user.add_role role
    status 204
  end
  delete '/users/:user_id/roles/:role_id' do |user_id, role_id|
    requires_role! :admin
    @user.remove_role find_role!(role_id)
    status 204
  end
  post '/forgot-password' do
    user_param_presence!
    # requesting a password reset
    #TODO rate limit / regen limit
    if params[:user][:username] && params[:user][:email]
      status 204
      user = User[username: params[:user][:username]]
      if user.nil?
        logger.warn "User #{params[:user][:username]} not found for password reset"
        return
      elsif user.email.nil? || user.email != params[:user][:email]
        logger.warn "User #{params[:user][:username]} found, but email #{params[:user][:email]} not found for password reset"
        return
      end

      expires = DateTime.now.next_day.iso8601
      id = user.id
      encrypted, iv = encrypt("#{id}/#{expires}")
      link = "#{link_to_reset}/#{Base64.urlsafe_encode64(encrypted)}/#{Base64.urlsafe_encode64(iv)}"
      email_password_reset_link user, link
      logger.info "Generated reset link and sent email for user #{user.username}, id #{user.id}, email #{user.email}"
      if ENV['RACK_ENV'] == 'development'
        logger.info ">> #{link}"
      end
    # trying to update a password based on a reset link
    elsif params[:user][:token] && params[:user][:iv] && params[:user][:password]
      status 204
      begin
        iv = Base64.urlsafe_decode64(params[:user][:iv])
        decrypted = decrypt(Base64.urlsafe_decode64(params[:user][:token]), iv)
        id, date_s = decrypted.split("/", 2)
        logger.info "Reset request, id #{id}, expires #{date_s}"
        user = User[id: id]
        if user.nil?
          status 500
          raise "User with id #{id} not found"
        end
        date = DateTime.iso8601(date_s)
        if date < DateTime.now
          status 400
          raise "Token already expired at #{date_s}"
        end
        user.plaintext_password = params[:user][:password]
        if user.valid?
          user.save
          logger.info "Set new password for user #{user.username}, id #{user.id}, email #{user.email}"
          if ENV['RACK_ENV'] == 'development'
            logger.info ">> #{params[:user][:password]}"
          end
          email_password_changed user
        else
          logger.warn "Couldn't set new password for user #{user.username}, #{user.id}, email #{user.email}: #{user.errors.inspect}"
        end
      rescue => e
        logger.warn "Couldn't perform password reset: #{e}"
      end
    # other nefarious things
    else
      json_halt 400, "Invalid user object found in request payload"
    end
  end
  post '/users' do
    user_param_presence!
    params[:user].delete 'passwordConfirmation'
    # is there a better way to do this? TODO
    new_user = User.new params[:user]
    json_halt 400, new_user.errors unless new_user.valid?
    new_user.save
    status 201
    logger.info "#{new_user.username} successfully registered"
    json :id => new_user.id
  end
  get '/me' do
    requires_login!
    principal.to_json(include: [:roles,:avatar_url], except: [:active, :password, :salt, :avatar])
  end
  post '/me' do
    requires_login!
    user_param_presence!
    user = User[principal.id]
    password_changed = false
    if params[:user][:passwordCurrent]
      password_changed = true
      error_message = { :passwordCurrent => [ 'incorrect password' ] }
      json_halt 400, error_message unless user.password_matches?(params[:user][:passwordCurrent])

      params[:user].delete 'passwordConfirmation'
      params[:user].delete 'passwordCurrent'

      user.set_fields params[:user], [:password]
      json_halt 400, user.errors unless user.valid?

      e_password = user.encrypted_password(params[:user][:password] || "", user.salt)
      user.set_fields e_password, [:password]
    end

    user.set_fields params[:user], [:name, :email, :catchphrase]
    json_halt 400, user.errors unless user.valid?
    user.save
    status 200
    logger.info "#{user.username} successfully updated"
    email_password_changed(user) if password_changed
    json :id => user.id
  end
  post '/me/avatar' do
    json_halt 413, { :avatar => [ 'avatar must be less than 1mb' ] } if request.content_length.to_i > 1024 * 1024
    requires_login!
    user = User[principal.id]
    user.avatar_content_type = params[:file][:type]
    user.avatar = Sequel.blob(params[:file][:tempfile].read)
    json_halt 400, user.errors unless user.valid?
    user.save
    logger.info "#{user.username} avatar uploaded"
    status 204
  end
  helpers do
    def find_role!(role_id)
      role = Role[id: role_id]
      json_halt 400, "Role #{role_id} not found" if role.nil?
      role
    end
    def user_param_presence!
      json_halt 400, "No user object found in request payload" if params[:user].nil?
    end
  end
end
