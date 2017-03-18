class Match < Sequel::Model
  plugin :validation_helpers
  many_to_one :season_match_group, class: :SeasonMatchGroup, key: :season_match_group_id
  # TODO: i think this should end with "es" since its a *_to_many
  one_to_many :user_season_match, class: :UserSeasonMatch, order: :user_season_id
  def validate
    validates_integer :best_of
    validates_presence [:scheduled_for, :best_of, :description]
    super
  end

  def before_validation
    super
    self.best_of = 3 if best_of.nil?
  end

  def member?(user)
    user_id = if user.is_a? User
                user.id
              else
                user
              end
    # user season match is like 'match member'
    UserSeasonMatch.join(:users_seasons, id: :user_season_id).where(user_id: user_id, match_id: id).count != 0
  end

  def title
    "#{season_match_group.season.name} > #{season_match_group.name} > #{description}"
  end
end
