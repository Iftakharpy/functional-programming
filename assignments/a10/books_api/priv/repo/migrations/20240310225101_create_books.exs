defmodule BooksApi.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string
      add :isbn, :string
      add :description, :text
      add :price, :float
      add :authors, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:books, [:isbn])
  end
end
