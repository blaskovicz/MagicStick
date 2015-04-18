Sequel.migration do
  up do
    create_table?(:seasons) do
      primary_key :id
      String :name, :null => false, :size => 64
      DateTime :created_at
      DateTime :updated_at
      DateTime :starts, :null => false
      DateTime :ends, :null => false
      String :description, :null => true, :size => 4000
      FalseClass :is_archived, :null => false, :default => false
      FalseClass :invite_only, :null => false, :default => false
      TrueClass :allow_auto_join, :null => false, :default => true
      foreign_key :owner_id, :users, :null => false, :on_delete => :cascade, :on_update => :cascade
    end
    alter_table(:seasons) do
      add_index [:owner_id, :name], :unique => true
    end
    create_table?(:season_match_groups) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at
      String :name, :null => false, :size => 64
      foreign_key :season_id, :seasons, :null => false, :on_delete => :cascade, :on_update => :cascade
    end
    alter_table(:season_match_groups) do
      add_index [:name, :season_id], :unique => true
    end
    create_table?(:users_seasons) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at
      foreign_key :user_id, :users, :on_delete => :cascade, :on_update => :cascade
      foreign_key :season_id, :seasons, :on_delete => :cascade, :on_update => :cascade
    end
    alter_table(:users_seasons) do
      add_index [:user_id, :season_id], :unique => true
    end
    create_table?(:matches) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at
      DateTime :scheduled_for, :null => false
      DateTime :completed, :null => true
      foreign_key :season_match_group_id, :season_match_groups, :null => false, :on_delete => :cascade, :on_update => :cascade
      String :description, :null => true, :size => 4000
    end
    create_table?(:users_seasons_matches) do
      DateTime :created_at
      DateTime :updated_at
      TrueClass :won, :null => true
      foreign_key :user_season_id, :users_seasons, :on_delete => :cascade, :on_update => :cascade
      foreign_key :match_id, :matches, :on_delete => :cascade, :on_update => :cascade
      primary_key [:user_season_id, :match_id]
    end
    create_table?(:matches_comments) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at
      foreign_key :user_id, :users, :on_delete => :cascade, :on_update => :cascade
      foreign_key :match_id, :matches, :on_delete => :cascade, :on_update => :cascade
      String :comment, :null => false, :size => 4000
      FalseClass :hidden, :null => false, :default => false
    end
    create_table?(:seasons_comments) do
      primary_key :id
      foreign_key :user_id, :users, :on_delete => :cascade, :on_update => :cascade
      foreign_key :season_id, :seasons, :on_delete => :cascade, :on_update => :cascade
      DateTime :created_at
      DateTime :updated_at
      String :comment, :null => false, :size => 4000
      FalseClass :hidden, :null => false, :default => false      
    end
    create_table?(:seasons_invites) do
      primary_key :id
      DateTime :created_at
      DateTime :updated_at
      foreign_key :user_id, :users, :on_delete => :cascade, :on_update => :cascade
      foreign_key :season_id, :seasons, :on_delete => :cascade, :on_update => :cascade
    end
  end
  down do
    drop_table(:seasons_comments, :matches_comments, :users_seasons_matches, :matches, :users_seasons, :season_match_groups, :seasons)
  end
end
