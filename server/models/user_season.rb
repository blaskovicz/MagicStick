class UserSeason < Sequel::Model
  plugin :validation_helpers
  one_to_one :user
  one_to_one :season
  def validate
    validates_unique [:user_id, :season_id]
    super
  end
end
