Sequel.migration do
  up do
    alter_table(:users_seasons_matches) do
      add_column :game_wins, Integer, :null => false, :default => 0
    end
    alter_table(:matches) do
      add_column :best_of, Integer, :null => false, :default => 3
    end
  end
  down do
    alter_table(:users_seasons_matches) do
      drop_column :game_wins
    end
    alter_table(:matches) do
      drop_column :best_of
    end
  end
end
