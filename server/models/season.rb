require 'date'
class Season < Sequel::Model
  plugin :validation_helpers
  one_to_many :season_match_groups
  many_to_many :users, :left_key => :season_id, :right_key => :user_id, :join_table => :users_seasons
  def validate
    super
    validates_presence [:starts, :ends, :allow_auto_join, :invite_only, :owner_id]
    validates_min_length 4, :name
    validates_max_length 64, :name
    validates_min_length 4, :description
    validates_max_length 4000, :description
    validates_unique [:owner_id, :name]
    join_mode_invalid = self.invite_only == self.allow_auto_join
    errors.add(:allow_auto_join, 'is mutually exclusive of invite only mode') if join_mode_invalid
    errors.add(:invite_only, 'is mutually exclusive of auto join mode') if join_mode_invalid
  end
  def before_create
    super
    if self.invite_only
      self.allow_auto_join = false
    elsif self.allow_auto_join
      self.invite_only = true
    end
    self.created = DateTime.now
    self.archived = false
  end
end
