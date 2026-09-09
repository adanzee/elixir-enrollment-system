defmodule StudentLive.AssignmentFixtures do
  alias StudentLive.Schemas.Assignment
  alias StudentLive.Repo

  def assignment_fixture(course_id, attrs \\ %{}) do
    default_attrs = %{
      title: Faker.Lorem.sentence(),
      description: Faker.Lorem.paragraph(),
      maximum_submissions_per_student: Enum.random(1..3),
      course_id: course_id
    }

    attrs = Map.merge(default_attrs, attrs)

    %Assignment{}
    |> struct(attrs)
    |> Repo.insert!()
  end
end
