Sequel.migration do
  up do
    create_table?(:roles) do
      primary_key :id
      String :name, :size => 32, :unique => true, :null => false
      String :description, :null => true
      # These need to be in every table due to Sequel::Timestamps plugin
      DateTime :created_at
      DateTime :updated_at
    end
    create_table?(:users) do
      primary_key :id
      String :username, :size => 32, :unique => true, :null => false
      String :password, :size => 128, :null => false
      String :salt, :size => 8, :null => false
      String :email, :size => 128, :null => false
      String :catchphrase, :null => true
      File :avatar, :null => true
      DateTime :created_at
      DateTime :updated_at
      DateTime :last_login, :null => true
      TrueClass :active, :null => false, :default => true
    end
    create_table?(:users_roles) do
      DateTime :created_at
      DateTime :updated_at
      foreign_key :user_id, :users, :on_delete => :cascade, :on_update => :cascade
      foreign_key :role_id, :roles, :on_delete => :cascade, :on_update => :cascade
      primary_key [:user_id, :role_id]
      index [:user_id, :role_id], :unique => true
    end
    [
      {:name => "admin", :description => "site admin"},
      {:name => "moderator", :description => "site helper"}
    ].each do |role|
      self[:roles].insert(role)
    end
  end
  down do
    drop_table(:users_roles, :users, :roles)
  end
end
