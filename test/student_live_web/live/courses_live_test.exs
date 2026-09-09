defmodule StudentLiveWeb.CoursesLiveTest do
  use StudentLiveWeb.ConnCase, async: true

  describe "Courses Page" do
    defp create_student(password \\ "Password123!") do
    attrs = %{
      name: Faker.Person.name(),
      email: Faker.Internet.email(),
      password: password,
      contact: Faker.Phone.EnUs.phone()
    }

    {:ok, student} = Accounts.create_student(attrs)

    student
  end
  defp create_course do
    %Course{
      title: Faker.Lorem.sentence(),
      description: Faker.Lorem.paragraph(),
      outline_pdf_path: "/uploads/#{Faker.File.file_name()}",
      start_date: Date.add(Date.utc_today(), 3),
      end_date: Date.add(Date.utc_today(), 33),
      maximum_capacity: Faker.Random.random_between(1, 10)
    }
    |> Repo.insert!()
  end

  test "shows view details and unenroll options for enrolled course", %{conn: conn} do
    student = create_student()
    course = create_course()

    enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, view, _html} = live(conn, "/dashboard")

    view
    |> element("#enrolled-course-#{course.id}")
    |> render_click()

    html = render(view)

    assert html =~ "View Details"
    assert html =~ "Unenroll"
  end

  test "clicking unenroll shows confirmation dialog", %{conn: conn} do
    student = create_student()
    course = create_course()

    enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, view, _html} = live(conn, "/dashboard")

    view
    |> element("#enrolled-course-#{course.id}")
    |> render_click()

    html =
      view
      |> element("#unenroll-course-#{course.id}")
      |> render_click()

    assert html =~ "Are you sure you want to unenroll from this course?"
    assert html =~ "OK"
    assert html =~ "Cancel"
  end

  test "canceling unenrollment keeps student enrolled", %{conn: conn} do
    student = create_student()
    course = create_course()

    enrollment = enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, view, _html} = live(conn, "/dashboard")

    view
    |> element("#enrolled-course-#{course.id}")
    |> render_click()

    view
    |> element("#unenroll-course-#{course.id}")
    |> render_click()

    view
    |> element("#cancel-unenroll")
    |> render_click()

    assert Repo.get!(Enrollment, enrollment.id)
  end

  test "confirming unenrollment removes student from course", %{conn: conn} do
    student = create_student()
    course = create_course()

    enrollment = enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, view, _html} = live(conn, "/dashboard")

    view
    |> element("#enrolled-course-#{course.id}")
    |> render_click()

    view
    |> element("#unenroll-course-#{course.id}")
    |> render_click()

    view
    |> element("#confirm-unenroll")
    |> render_click()

    assert Repo.get(Enrollment, enrollment.id) == nil
  end

  test "view details navigates to course page", %{conn: conn} do
    student = create_student()
    course = create_course()

    enroll_student(student.id, course.id)

    conn = log_in_student(conn, student)

    {:ok, view, _html} = live(conn, "/dashboard")

    view
    |> element("#enrolled-course-#{course.id}")
    |> render_click()

    view
    |> element("#view-course-#{course.id}")
    |> render_click()

    assert_redirect(view, "/courses/#{course.id}")
  end
end
end
