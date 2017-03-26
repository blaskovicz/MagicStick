require 'digest/sha2'
class User < Sequel::Model
  plugin :validation_helpers
  one_to_many :season_comments
  one_to_many :user_identities
  many_to_many :roles, left_key: :user_id, right_key: :role_id, join_table: :users_roles
  many_to_many :season_memberships, class: :Season, left_key: :user_id, right_key: :season_id, join_table: :users_seasons
  one_to_many :managed_seasons, class: :Season, key: :owner_id
  def validate
    super
    validates_presence [:username, :password, :email]
    validates_presence :name if new? # initial users don't have a name defined
    validates_min_length 8, :password
    validates_min_length 4, :username
    validates_unique :email
    validates_unique :username
    errors.add(:username, 'cannot contain @ character') if !username.nil? && username.index('@')
    validates_format(/[^@]+@[^@]+\..+/, :email, message: 'is not a valid email address')
    errors.add(:avatar_mime_type, 'unsupported content-type') unless [nil, 'image/png', 'image/jpeg', 'image/gif'].include? avatar_content_type
  end

  def auth_payload
    to_json(include: [:roles, :avatar_url, :user_identities], except: [:active, :password, :salt, :avatar])
  end

  def self.generate_password
    %w{! @ # $ % ^ & * ( ) - + 0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z}.sample(20).join
  end

  def before_create
    super
    self.active = true
    e_password = encrypted_password(password)
    self.salt = e_password[:salt]
    self.password = e_password[:password]
  end

  def generate_salt
    ('a'..'z').to_a.sample(8).join
  end

  def plaintext_password=(plaintext_password)
    return unless plaintext_password.length >= 8 # TODO: hack for now, should call validator
    fields = encrypted_password(plaintext_password, salt)
    self.password = fields[:password]
    self.salt = fields[:salt]
  end

  def encrypted_password(raw_password, salt = nil)
    salt = generate_salt if salt.nil?
    {
      password: Digest::SHA2.new(512).hexdigest(raw_password + salt),
      salt: salt
    }
  end

  def password_matches?(raw_password)
    return false if salt.nil? || password.nil?
    password == encrypted_password(raw_password, salt)[:password]
  end

  def avatar_url
    if avatar
      "/api/auth/users/#{id}/avatar"
    else
      hash = Digest::MD5.hexdigest(email ? email.strip.downcase : '')
      "https://secure.gravatar.com/avatar/#{hash}?s=155&d=identicon"
    end
  end

  # TODO: add a concept of visibility that all classes can utilize
  def self.public_attrs
    [:id, :username, :name, :avatar_url, :catchphrase]
  end
end
