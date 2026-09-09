defmodule StudentLive.CourseFixtures do
  alias StudentLive.Schemas.Course
  alias StudentLive.Repo

  def course_fixture(attrs \\ %{}) do
    default_attrs = %{
      title: Faker.Lorem.sentence(),
      description: Faker.Lorem.paragraph(),
      outline_pdf_path: "/uploads/#{Faker.File.file_name()}",
      start_date: Date.add(Date.utc_today(), 3),
      end_date: Date.add(Date.utc_today(), 33),
      maximum_capacity: Enum.random(1..10)
    }

    attrs = Map.merge(default_attrs, attrs)

    %Course{}
    |> struct(attrs)
    |> Repo.insert!()
  end
end
