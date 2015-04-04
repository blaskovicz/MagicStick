Sequel.migration do
  up do
    create_table?(:roles) do
      primary_key :id
      String :name, :size => 32, :unique => true, :null => false
      String :description, :null => true
    end
    create_table?(:users) do
      primary_key :id
      String :username, :size => 32, :unique => true, :null => false
      String :password, :size => 128, :null => false
      String :salt, :size => 8, :null => false
      String :email, :size => 128, :null => false
      String :catchphrase, :null => true
      File :avatar, :null => true
      DateTime :created, :null => false
      DateTime :last_login, :null => true
      TrueClass :active, :null => false, :default => true
    end
    create_table?(:users_roles) do
      foreign_key :user_id, :users
      foreign_key :role_id, :roles
      primary_key [:user_id, :role_id]
      index [:user_id, :role_id]
    end
  end
  down do
    drop_table(:users_roles, :users, :roles)
  end
end
