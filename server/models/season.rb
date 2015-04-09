require 'date'
class Season < Sequel::Model
  plugin :validation_helpers
  one_to_many :season_match_groups
  many_to_many :members, :class => :User, :left_key => :season_id, :right_key => :user_id, :join_table => :users_seasons
  many_to_one :owner, :class => :User, :key => :owner_id
  def validate
    validates_presence [:starts, :ends, :allow_auto_join, :invite_only, :owner_id]
    validates_min_length 4, :name
    validates_max_length 64, :name
    validates_min_length 4, :description
    validates_max_length 4000, :description
    validates_unique [:owner_id, :name]
    join_mode_invalid = self.invite_only == self.allow_auto_join and self.invite_only
    if self.invite_only == true and self.allow_auto_join == true
      errors.add(:allow_auto_join, 'cannot be set if invite only is also enalbed')
      errors.add(:invite_only, 'cannot be set if allow auto join is also enabled')
    end
    super
  end
  def before_create
    self.invite_only = false if not self.invite_only
    self.allow_auto_join = false if not self.allow_auto_join
    self.created = DateTime.now
    self.is_archived = false
    super
  end
end
