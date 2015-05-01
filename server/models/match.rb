class Match < Sequel::Model
  plugin :validation_helpers
  many_to_one :season_match_group, :class => :SeasonMatchGroup, :key => :season_match_group_id
  # TODO i think this should end with "es" since its a *_to_many
  one_to_many :user_season_match, :class => :UserSeasonMatch, :order => :user_season_id
  def validate
    validates_integer :best_of
    validates_presence [:scheduled_for, :best_of]
    super
  end
  def before_validation
    super
    self.best_of = 3 if self.best_of.nil?
  end
end
