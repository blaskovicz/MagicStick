require 'digest/sha2'
class User < Sequel::Model
  plugin :validation_helpers
  one_to_many :season_comments
  many_to_many :roles, :left_key => :user_id, :right_key => :role_id, :join_table => :users_roles
  many_to_many :season_memberships, :class => :Season, :left_key => :user_id, :right_key => :season_id, :join_table => :users_seasons
  one_to_many :managed_seasons, :class => :Season, :key => :owner_id
  def validate
    super
    validates_presence [:username, :password, :email]
    validates_presence :name if new? # initial users don't have a name defined
    validates_min_length 8, :password
    validates_min_length 4, :username
    validates_unique :username
    validates_format /[^@]+@[^@]+\..+/, :email, :message => "is not a valid email address"
    errors.add(:avatar_mime_type, 'unsupported content-type') unless [nil, 'image/png', 'image/jpeg', 'image/gif'].include? self.avatar_content_type
  end
  def before_create
    super
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
  def avatar_url
    hash = Digest::MD5.hexdigest(if self.email then self.email.strip.downcase else "" end)
    if self.avatar
      "/api/auth/users/#{self.id}/avatar"
    else
      hash = Digest::MD5.hexdigest(self.email ? self.email.strip.downcase : "")
      "https://secure.gravatar.com/avatar/#{hash}?s=155&d=identicon"
    end
  end
  # TODO add a concept of visibility that all classes can utilize
  def self.public_attrs
    [:username, :id]
  end
end
