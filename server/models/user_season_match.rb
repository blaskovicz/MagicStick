#TODO finish this class and utilize in other related classes / controllers
class UserSeasonMatch < Sequel::Model(:users_seasons_matches)
  plugin :validation_helpers
  many_to_one :matches, :class => :Match
#  many_to_many :wtf, :class => :UserSeason, :dataset => (proc do |r|
#    r.associated_dataset.select_all(:user_season)
#  end)
# Sequel REFUSES to let me make this join no matter which way I try it due to some random primary key 
#  one_to_one :user_season
#  one_to_one :user, :dataset => (proc do |r|
#    User.where(id: $DB[:user_season].where(id: self.user_season_id).select(:user_id))
#  end), :class => User
  def validate
    validates_unique [:user_season_id, :match_id]
    super
  end
end
