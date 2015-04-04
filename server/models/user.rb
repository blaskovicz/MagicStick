require 'date'
require 'digest/sha2'
class User < Sequel::Model
  plugin :validation_helpers
  many_to_many :roles, :left_key => :user_id, :right_key => :role_id, :join_table => :users_roles
  def validate
    super
    validates_presence [:username, :password, :email]
    validates_min_length 8, :password
    validates_min_length 4, :username
    validates_unique :username
    validates_format /[^@]+@[^@]+\..+/, :email, :message => "is not a valid email address"
  end
  def before_create
    super
    self.created = DateTime.now
    self.active = true
    e_password = encrypted_password(self.password)
    self.salt = e_password[:salt]
    self.password = e_password[:password]
  end
  def encrypted_password(raw_password, salt = ('a'..'z').to_a.shuffle[0,8].join)
    {
      :password => Digest::SHA2.new(512).hexdigest(raw_password + salt),
      :salt => salt
    }
  end
  def password_matches?(raw_password)
    return false if self.salt.nil? or self.password.nil?
    self.password == encrypted_password(raw_password, self.salt)[:password]
  end
end
