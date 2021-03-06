class Season < Sequel::Model
  plugin :validation_helpers
  one_to_many :season_match_groups
  one_to_many :season_comments
  many_to_many :members, class: :User, left_key: :season_id, right_key: :user_id, join_table: :users_seasons
  many_to_one :owner, class: :User, key: :owner_id
  def validate
    validates_presence [:starts, :ends, :allow_auto_join, :invite_only, :owner_id]
    validates_min_length 4, :name
    validates_max_length 64, :name
    validates_min_length 4, :description
    validates_max_length 4000, :description
    validates_unique [:owner_id, :name]
    if invite_only == allow_auto_join
      errors.add(:allow_auto_join, 'cannot be the same as invite_only')
      errors.add(:invite_only, 'cannot be the same as allow_auto_join')
    end
    super
  end

  def before_validation
    self.invite_only = false unless invite_only
    self.allow_auto_join = false unless allow_auto_join
    self.is_archived = false
    super
  end

  def member?(user)
    id = if user.is_a? User
           user.id
         else
           user
         end
    !members_dataset.where(users__id: id).first.nil?
  end
end
