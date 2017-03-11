require 'date'
require 'openssl'
require 'digest/sha1'
require 'jwt'
module Auth
  def hmac_secret
    raise 'HMAC_SECRET not set' unless ENV.key? 'HMAC_SECRET'
    ENV['HMAC_SECRET']
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
    begin
      decoded_token = JWT.decode token, hmac_secret, true, algorithm: 'HS256'
      payload = decoded_token.first
      return unless payload['iss'] == 'magic-stick' # we only issue our own tokens for v1
      # TODO: maybe create user here if coming from oauth provider
      user = User[id: payload['sub']] # the subject is the user id
      if user
        logger.info "[auth/bearer] #{user.username} now logged in"
        return user
      else
        logger.warn "[auth/bearer] Invalid login attempt with jwt with payload #{payload.inspect}"
      end
    rescue => e # may be a jwt error like expired token
      logger.warn "[auth/bearer] Invalid login attempt with jwt #{token} (#{e})"
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
    # TODO: don't touch updated at
    user.last_login = DateTime.now
    user.save_changes
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
