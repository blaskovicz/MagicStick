require 'date'
require 'openssl'
require 'digest/sha1'
module Auth
  def requires_role!(*roles)
    requires_login!
    return if roles.nil?
    user = principal
    allowed_roles = roles.map { |role| role.to_s.downcase }
    user.roles.each do |role|
      return if allowed_roles.include?(role.name)
    end
    halt_403
  end
  def principal
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    provided_basic_creds =
      @auth.provided? and
      @auth.basic? and
      @auth.credentials.all?{|part| part.length >= 4 } #TODO tie in with User validators
    return nil unless provided_basic_creds
    username_or_email, password = @auth.credentials.first, @auth.credentials.last
    lookup_by = [:username]
    # if the user specified an @, try lookup by email first
    if username_or_email.index('@')
      lookup_by.unshift :email
    else
      lookup_by.push :email
    end

    lookup_by.each do |attr|
      user = User.where(attr => username_or_email).first
      if user and user.password_matches? password
        return user
      end
    end
    logger.warn "Invalid login attempt with username_or_email #{username_or_email}"
    nil
  end
  def requires_login!
    user = principal
    halt_401 if user.nil?
    halt_403 unless user.active
    user.last_login = DateTime.now
    user.save_changes
  end
  def halt_500
    json_halt 500, "An error occurred"
  end
  def halt_401
    # although technically more correct, dont set this header to avoid browser prompts
    #headers['WWW-Authenticate'] = %(Basic Realm="Magic MagicStick Area")
    json_halt 401, "Insufficient credentials provided"
  end
  def halt_403
    json_halt 403, "You don't have the correct priviledges to access this resource"
  end
  def encrypt(string)
    assert_key
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
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
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = Digest::SHA1.hexdigest(ENV['SECRET'])
    cipher.iv = iv
    decrypted = cipher.update(string)
    decrypted << cipher.final
    decrypted
  end
  private
  def assert_key
    raise 'SECRET unset' unless ENV.has_key? 'SECRET'
  end
end
