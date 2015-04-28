Sequel.migration do
  up do
    alter_table(:users) do
      add_column :name, String, :size => 70, :null => true
      add_column :avatar_content_type, String, :size => 64, :null => true
    end
  end
  down do
    alter_table(:users) do
      drop_column :name
      drop_column :avatar_content_type
    end
  end
end
