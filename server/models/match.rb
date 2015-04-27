class Match < Sequel::Model
  plugin :validation_helpers
  many_to_one :season_match_group, :class => :SeasonMatchGroup, :key => :season_match_group_id
  # TODO i think this should end with "es" since its a *_to_many
  one_to_many :user_season_match, :class => :UserSeasonMatch
  def validate
    validates_presence :scheduled_for
    super
  end
end
