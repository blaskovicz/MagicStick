class UserSeason < Sequel::Model(:users_seasons)
  plugin :validation_helpers
  many_to_one :user
  many_to_one :season
  def validate
    validates_unique [:user_id, :season_id]
    super
  end
end
