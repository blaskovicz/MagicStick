require 'date'
require 'openssl'
require 'digest/sha1'
require 'jwt'
require 'uri'
module Auth
  def hmac_secret
    raise 'HMAC_SECRET not set' unless ENV.key? 'HMAC_SECRET'
    ENV['HMAC_SECRET']
  end

  def auth0_secret
    raise 'AUTH0_CLIENT_SECRET not set' unless ENV.key? 'AUTH0_CLIENT_SECRET'
    ENV['AUTH0_CLIENT_SECRET']
  end

  def requires_role!(*roles)
    requires_login!
    return if roles.nil?
    user = principal
    allowed_roles = roles.map { |role| role.to_s.downcase }
    halt_403 unless user.roles.any? { |role| allowed_roles.include?(role.name) }
  end

  def principal
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    return unless @auth.provided?
    return decode_basic_user if @auth.scheme == 'basic'
    return decode_jwt_user if @auth.scheme == 'bearer'
    logger.warn "[auth] unknown scheme #{@auth.scheme} and payload #{@auth.params}"
    nil
  end

  def decode_basic_user
    username_or_email = @auth.username
    password = @auth.credentials.last
    lookup_by = [:username]
    # if the user specified an @, try lookup by email first
    if username_or_email.index('@')
      lookup_by.unshift :email
    else
      lookup_by.push :email
    end
    lookup_by.each do |attr|
      user = User.where(attr => username_or_email).first
      if user && user.password_matches?(password)
        logger.info "[auth/basic] #{user.username} now logged in"
        return user
      end
    end
    logger.warn "[auth/basic] Invalid login attempt with username_or_email #{username_or_email}"
    nil
  end

  def decode_jwt_user(token = @auth.params)
    payload_unsafe = nil
    begin
      user = nil
      payload = nil
      # check the payload without validating to determine which issuer
      payload_unsafe = JWT.decode(token, nil, false, algorithm: 'HS256').first
      # if we're from magic stick, use our own secret and payload for lookup
      if payload_unsafe['iss'] == 'magic-stick'
        payload = JWT.decode(token, hmac_secret, true, algorithm: 'HS256').first
        user = User[id: payload['sub']] # the subject is the user id
      # if we're from auth0, use their format, potentially creating a user
      elsif URI(payload_unsafe['iss']).host.end_with? 'auth0.com'
        payload = JWT.decode(token, auth0_secret, true, algorithm: 'HS256').first
        identity = UserIdentity[provider_id: payload['sub']]
        if identity
          user = identity.user
        else
          user = User[email: payload['email']]
          if user.nil?
            logger.info "[auth/bearer] attempting to create user (#{payload.inspect})"
            # google-oauth2|12345 -> google_user_12345
            sub = payload['sub'].split('|')
            user = User.new(
              email: payload['email'],
              username: "#{sub.first.split('-').first}_user_#{sub.last}"
            )
            user.name = payload['name'] ? payload['name'] : user.username
            raw_password = User.generate_password
            user.plaintext_password = raw_password
            raise "Failed to create user #{user.errors.inspect}" unless user.save
            email_welcome user, password: raw_password
            invite_to_slack user
          end
          # add identity
          if user.user_identities_dataset.where(provider_id: payload['sub']).first.nil?
            logger.info "[auth/bearer] attempting to associate user #{user.id} (#{user.email}) with identity (#{payload.inspect})"
            user.add_user_identity UserIdentity.new(provider_id: payload['sub'])
          end
        end
      end
      if user
        logger.info "[auth/bearer] #{user.username} logged in (#{payload.inspect})"
        return user
      else
        logger.warn "[auth/bearer] Invalid login attempt with jwt with payload #{payload_unsafe.inspect}"
      end
    rescue => e # may be a jwt error like expired token
      logger.warn "[auth/bearer] Invalid login attempt with jwt #{token} => #{payload_unsafe ? payload_unsafe.inspect : '?'} (#{e.class}: #{e})"
    end
    nil
  end

  def encode_jwt(user)
    return unless user.is_a? User
    # jwt that expires after an hour
    payload = { sub: user.id, exp: Time.now.to_i + 3600, iss: 'magic-stick', user: JSON.parse(user.auth_payload) }
    JWT.encode(payload, hmac_secret, 'HS256')
  end

  def requires_login!
    user = principal
    halt_401 if user.nil?
    halt_403 unless user.active
    user.this.update(last_login: DateTime.now)
  end

  def halt_500
    json_halt 500, 'An error occurred'
  end

  def halt_401
    # although technically more correct, dont set this header to avoid browser prompts
    # headers['WWW-Authenticate'] = %(Basic Realm="Magic MagicStick Area")
    json_halt 401, 'Insufficient credentials provided'
  end

  def halt_403
    json_halt 403, "You don't have the correct priviledges to access this resource"
  end

  def encrypt(string)
    assert_key
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    cipher.encrypt
    cipher.key = Digest::SHA1.hexdigest(ENV['SECRET'])
    iv = cipher.random_iv
    cipher.iv = iv
    encrypted = cipher.update(string)
    encrypted << cipher.final
    [encrypted, iv]
  end

  def decrypt(string, iv)
    assert_key
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    cipher.decrypt
    cipher.key = Digest::SHA1.hexdigest(ENV['SECRET'])
    cipher.iv = iv
    decrypted = cipher.update(string)
    decrypted << cipher.final
    decrypted
  end

  private

  def assert_key
    raise 'SECRET unset' unless ENV.key? 'SECRET'
  end
end
