require 'date'
module Auth
  def requires_login!
    if not logged_in?
      halt_401
    end
  end
  def requires_role!(*roles)
    requires_login!
    return if roles.nil?
    user = full_user
    halt_500 if user.nil?
    halt_403 unless user.active
    allowed_roles = roles.map { |role| role.to_s.downcase }
    user.roles.each do |role|
      return if allowed_roles.include?(role.name)
    end
    halt_403
  end
  def logged_in?
    not current_user.nil?
  end
  def logout
    session[:user] = nil
  end
  def login(user_id)
    session[:user] = user_id unless logged_in?
    full_user.last_login = DateTime.now
  end
  def current_user
    session[:user]
  end
  def full_user?
    not full_user.nil?
  end
  def full_user
    return nil if current_user.nil?
    User[id: session[:user]]
  end
  def halt_500
    halt 500, "An error occurred"
  end
  def halt_401
    halt 401, "Insufficient credentials provided"
  end
  def halt_403
    halt 403, "You don't have the correct priviledges to access this resource"
  end
end
