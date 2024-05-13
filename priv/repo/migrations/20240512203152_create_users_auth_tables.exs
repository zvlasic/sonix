defmodule Sonix.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :citext, null: false
      timestamps(type: :utc_datetime)
    end

    create table(:users_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :token, :binary, null: false
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:token])
  end
end
