defmodule BooksApi.Store.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :description, :string
    field :title, :string
    field :isbn, :string
    field :price, :float
    field :authors, {:array, :string}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :isbn, :description, :price, :authors])
    |> validate_required([:title, :isbn, :description, :price, :authors])
    |> unique_constraint(:isbn)
  end
end
