class SeasonComment < Sequel::Model(:seasons_comments)
  plugin :validation_helpers
  many_to_one :season
  many_to_one :user
  def validate
    validates_presence [:user_id, :season_id]
    validates_min_length 1, :comment
    validates_max_length 4000, :comment
    super
  end
end
