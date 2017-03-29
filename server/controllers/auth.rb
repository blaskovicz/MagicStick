require 'date'
require 'base64'
require 'cgi'
class AuthController < ApplicationController
  before %r{^/users/+([^/]+)} do |user_id|
    @user = User[id: user_id]
    json_halt 404, "User #{user_id} couldn't be found" if @user.nil?
  end
  get '/roles' do
    requires_role! :admin
    json roles: Role.all
  end
  get '/users' do
    if params[:limitted]
      requires_login!
      params[:matching] ||= ''
      User.where(Sequel.expr(active: true) & (
          Sequel.ilike(:username, '%' + params[:matching] + '%') |
          Sequel.ilike(:name, '%' + params[:matching] + '%') |
          Sequel.ilike(:email, params[:matching])
      ))
          .to_json(root: true, only: User.public_attrs)
    else
      requires_role! :admin
      User.to_json(root: true, exclude: :avatar)
    end
  end
  get '/users/:user_id' do
    requires_role! :admin
    json user: @user
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
    json roles: @user.roles
  end
  post '/users/:user_id/roles/:role_id' do |user_id, role_id|
    requires_role! :admin
    role = find_role! role_id
    unless ::Database[:users_roles].where(user_id: user_id, role_id: role_id).first.nil?
      json_halt 409, "User #{user_id} already in role #{role_id}"
    end
    @user.add_role role
    status 204
  end
  delete '/users/:user_id/roles/:role_id' do |_user_id, role_id|
    requires_role! :admin
    @user.remove_role find_role!(role_id)
    status 204
  end
  post '/forgot-password' do
    user_param_presence!
    # requesting a password reset
    # TODO: rate limit / regen limit
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

      generated = DateTime.now.iso8601
      expires = DateTime.now.next_day.iso8601
      id = user.id
      encrypted, iv = encrypt("#{id}/#{expires}/#{generated}")
      link = "#{link_to_reset}/#{CGI.escape(Base64.urlsafe_encode64(encrypted))}/#{CGI.escape(Base64.urlsafe_encode64(iv))}"
      email_password_reset_link user, link
    # trying to update a password based on a reset link
    elsif params[:user][:token] && params[:user][:iv] && params[:user][:password]
      begin
        iv = Base64.urlsafe_decode64(CGI.unescape(params[:user][:iv]))
        decrypted = decrypt(Base64.urlsafe_decode64(CGI.unescape(params[:user][:token])), iv)
        id, expires_at, generated_at = decrypted.split('/', 3)
        logger.info "Password reset request, id #{id}, expires #{expires_at}, generated #{generated_at}"
        user = User[id: id]
        raise "User with id #{id} not found" if user.nil?
        # did the token already expire?
        expire_at_p = DateTime.iso8601(expires_at)
        if expire_at_p < DateTime.now
          raise "Token already expired at #{expires_at}"
        end
        # did we already use the token?
        generated_at_p = DateTime.iso8601(generated_at)
        if DateTime.parse(user.updated_at.to_s) > generated_at_p
          raise "User was updated at #{user.updated_at}, which is newer than token generation, #{generated_at}"
        end
        user.plaintext_password = params[:user][:password]
        raise 'password not valid' unless user.valid?
        user.save
        email_password_changed user
        status 204
      rescue => e
        logger.warn "Couldn't perform password reset: #{e}"
        json_halt 400, 'The request could not be completed'
      end
    # other nefarious things
    else
      json_halt 400, 'Invalid user object found in request payload'
    end
  end
  post '/users' do
    # TODO: require email confirm, dont generate account row until user clicks button
    user_param_presence!
    params[:user].delete 'passwordConfirmation'
    # is there a better way to do this? TODO
    new_user = User.new params[:user]
    json_halt 400, new_user.errors unless new_user.valid?
    new_user.save
    status 201
    email_welcome new_user
    invite_to_slack new_user
    json id: new_user.id
  end
  put '/me/slack' do
    requires_login!
    invite_to_slack(principal)
  end
  post '/me/identities' do
    # TODO: send an email here, also potentially reset password in the event
    # someone reserved an email address+password via normal signup (until we verify email)
    requires_login!
    json_halt 400, 'No token found in request payload' if params[:token].nil?
    begin
      payload = JWT.decode(Base64.urlsafe_decode64(params[:token]), auth0_secret, true, algorithm: 'HS256').first
      identity = UserIdentity[provider_id: payload['sub']]
      json_halt 409, 'Provider identity already linked to account' unless identity.nil?
      principal.add_user_identity UserIdentity.new(provider_id: payload['sub'])
      logger.info "[link-account] linked #{payload.inspect} to account #{principal.id} <#{principal.email}>"
      status 204
    rescue => e
      logger.warn "[link-account] failed to link #{params[:token]} to account #{principal.id} <#{principal.email}> (#{e.class}: #{e})"
      json_halt 400, 'Unable to link account to provider identity'
    end
  end
  delete '/me/identities/:identity_id' do |id|
    requires_login!
    identity = principal.user_identities_dataset.first(id: id)
    status 204
    return if identity.nil?
    identity.destroy
  end
  get '/me' do
    requires_login!
    principal.auth_payload
  end
  get '/me/slack' do
    requires_login!
    { in_slack: in_slack?(principal) }.to_json
  end
  post '/login' do
    # get a user row from Auth header
    user = principal
    halt_401 if user.nil?
    status 200
    { token: Base64.urlsafe_encode64(encode_jwt(user)) }.to_json
  end
  post '/me' do
    requires_login!
    user_param_presence!
    user = User[principal.id]
    password_changed = false
    if params[:user][:passwordCurrent]
      password_changed = true
      error_message = { passwordCurrent: ['incorrect password'] }
      json_halt 400, error_message unless user.password_matches?(params[:user][:passwordCurrent])

      params[:user].delete 'passwordConfirmation'
      params[:user].delete 'passwordCurrent'

      user.set_fields params[:user], [:password]
      json_halt 400, user.errors unless user.valid?

      e_password = user.encrypted_password(params[:user][:password] || '', user.salt)
      user.set_fields e_password, [:password]
    end

    user.set_fields params[:user], [:name, :email, :catchphrase]
    json_halt 400, user.errors unless user.valid?
    user.save
    status 200
    logger.info "#{user.username} successfully updated"
    email_password_changed(user) if password_changed
    json id: user.id
  end
  post '/me/avatar' do
    json_halt 413, avatar: ['avatar must be less than 1mb'] if request.content_length.to_i > 1024 * 1024
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
      json_halt 400, 'No user object found in request payload' if params[:user].nil?
    end
  end
end
