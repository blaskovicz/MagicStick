require 'date'
class SeasonMatchGroup < Sequel::Model
  plugin :validation_helpers
  many_to_one :season
  one_to_many :matches, class: :Match, key: :season_match_group_id
  def validate
    super
    validates_presence [:name, :season_id]
    validates_max_length 64, :name
    validates_min_length 4, :name
    validates_unique [:season_id, :name]
  end
end
