class UserSeasonMatch < Sequel::Model(:users_seasons_matches)
  plugin :validation_helpers
  many_to_one :match
  many_to_one :user_season
  one_through_one :user, join_table: :users_seasons, left_primary_key: :user_season_id, left_key: :id
  def before_validation
    super
    self.game_wins = 0 if game_wins.nil?
  end

  def validate
    validates_integer :game_wins
    validates_unique [:user_season_id, :match_id]
    super
  end
end
