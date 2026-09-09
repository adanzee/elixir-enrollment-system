defmodule StudentLive.StudentFixtures do
  alias StudentLive.Accounts

  def student_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: Faker.Person.name(),
      email: Faker.Internet.email(),
      password: "Password123!",
      confirm_password: "Password123!"
    }

    attrs = Map.merge(default_attrs, attrs)

    {:ok, student} = Accounts.create_student(attrs)

    student
  end
end
