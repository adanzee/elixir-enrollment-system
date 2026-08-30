defmodule StudentLive.Schemas.Student do
  use Ecto.Schema
  import Ecto.Changeset

  schema "students" do
    field :name, :string
    field :email, :string
    field :hashed_password, :string
    field :password, :string, virtual: true
    field :confirm_password, :string, virtual: true

    has_many :enrollments, StudentLive.Schemas.Enrollment
    has_many :courses, through: [:enrollments, :course]
    has_many :submissions, StudentLive.Schemas.Submission
    has_many :password_reset_tokens, StudentLive.Schemas.PasswordResetToken

    timestamps()
  end

 def changeset(student, attrs) do
    student
    |> cast(attrs, [:name, :email, :password, :confirm_password])
    |> validate_required([:name, :email, :password, :confirm_password])
    |> validate_confirm_password()
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces")
    |> validate_length(:password, min: 8, max: 12)
    |> validate_format(:password, ~r/[a-zA-Z]/,
      message: "must contain at least one letter")
    |> validate_format(:password, ~r/\d/,
      message: "must contain at least one number")
    |> validate_format(:password, ~r/[!@#$&*]/,
      message: "must contain at least one special character")
    |> unique_constraint(:email, message: "has already been taken")
    |> pass_hash()
  end


  def pass_hash(changeset) do
    if changeset.valid? do
      case get_change(changeset, :password) do
        password when is_binary(password) and password != "" ->
          put_change(changeset, :hashed_password,
            Bcrypt.hash_pwd_salt(password)
          )

        _ ->
          changeset
      end
    else
      changeset
    end
  end

  defp validate_confirm_password(changeset) do
    password = get_field(changeset, :password)
    confirm_password = get_field(changeset, :confirm_password)

    if password == confirm_password do
      changeset
    else
      add_error(changeset, :confirm_password, "does not match password")
    end
  end

end
