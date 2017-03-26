Sequel.migration do
  up do
    create_table?(:user_identities) do
      primary_key :id
      String :provider_id, null: false, unique: true
      DateTime :created_at
      DateTime :updated_at
      foreign_key :user_id, :users, on_delete: :cascade, on_update: :cascade
    end
  end
  down do
    drop_table(:user_identities)
  end
end
