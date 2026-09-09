defmodule StudentLiveWeb.Test.HomePage do
  use StudentLiveWeb.ConnCase, async: true

 describe "available course page" do
  test "render course information", %{conn: conn} do
    course = %Course{
    title: Faker.Lorem.sentence(),
    description: Faker.Lorem.paragraph(),
    outline_pdf_path: "/uploads/#{Faker.File.file_name()}",
    start_date: Date.add(Date.utc_today(), 3),
    end_date: Date.add(Date.utc_today(), 33),
    maximum_capacity: Faker.Random.random_between(1, 10)
    }

    course = Repo.insert!(course)
    {:ok, _view, html} = live(conn, "/courses")

    assert html =~ course.title
    assert html =~ course.description
    assert html =~ "Register"
  end

  test "logged in user navigate to course registration", %{conn: conn} do
    student = %Student{
      name: Faker.Internet.name(),
      email: Faker.Internet.email(),
      password: "Password123"
    }

    student = Repo.insert(student)

    course = %Course{
    title: Faker.Lorem.sentence(),
    description: Faker.Lorem.paragraph(),
    outline_pdf_path: "/uploads/#{Faker.File.file_name()}",
    start_date: Date.add(Date.utc_today(), 3),
    end_date: Date.add(Date.utc_today(), 33),
    maximum_capacity: Faker.Random.random_between(1, 10)
    }
    course = Repo.insert(course)

    conn = UserAuth.log_in_student(conn, student)
    {:ok, view, html} = live(conn, "courses")

    html = render_click(view, "register", %{"course_title" => course.title})
    assert html =~ "/course/register/#{course.id}"
  end

  test "unauthenticated user navigate to course registration", %{conn: conn} do
    course = %Course{
    title: Faker.Lorem.sentence(),
    description: Faker.Lorem.paragraph(),
    outline_pdf_path: "/uploads/#{Faker.File.file_name()}",
    start_date: Date.add(Date.utc_today(), 3),
    end_date: Date.add(Date.utc_today(), 33),
    maximum_capacity: Faker.Random.random_between(1, 10)
    }
    course = Repo.insert(course)

    {:ok, view, html} = live(conn, "courses")

    html = render_click(view, "register", %{"course_title" => course.title})
    assert html =~ "/register"
  end

  test "authenticated user navigate to dashboard", %{conn: conn} do
    student = %Student{
      name: Faker.Internet.name(),
      email: Faker.Internet.email(),
      password: "Password123"
    }

    student = Repo.insert(student)

    conn = UserAuth.log_in_student(conn, student)
    {:ok, _view, html} = live(conn, "/dashboard")

    assert html =~ "Dashboard"
    assert html =~ student.name
    assert html =~ student.email
  end

  test "unauthenticated user navigate to dashboard", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/dashboard")

    assert html =~ "You must log in to access this page."
    assert html =~ "/register"
  end
  end
end
