class Role < Sequel::Model
  many_to_many :users, :left_key => :role_id, :right_key => :user_id, :join_table => :users_roles
end
