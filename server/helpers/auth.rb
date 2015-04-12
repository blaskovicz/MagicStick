require 'date'
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
      @auth.credentials
    return nil unless provided_basic_creds
    user = User[username: @auth.credentials.first]
    return nil if user.nil?
    user.password_matches?(@auth.credentials.last) ? user : nil
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
end
