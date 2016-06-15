Sequel.migration do
  up do
    alter_table(:users) do
      add_unique_constraint :email, name: :unique_user_email
    end
  end
  down do
    alter_table(:users) do
      drop_constraint :unique_user_email
    end
  end
end
