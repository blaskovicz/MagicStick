class UserIdentity < Sequel::Model
  plugin :validation_helpers
  many_to_one :user
  def validate
    validates_unique [:provider_id]
    validates_presence [:user_id, :provider_id]
    super
  end
end
