class Match < Sequel::Model
  plugin :validation_helpers
  many_to_one :season_match_group, :class => :SeasonMatchGroup, :key => :season_match_group_id
  # temporary hack due to issues with UserSeasonMatch class
  one_to_many :user_season_match, :class => :UserSeasonMatch
#  many_to_many :participants, :dataset => ( proc do |r|
#    User.join(:users_seasons, user_id: :id).join(:users_seasons_matches, user_season_id: :id).where(match_id: self.id)
#  end), :class => :User
  def validate
    validates_presence :scheduled_for
    super
  end
end
