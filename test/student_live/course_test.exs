# test/student_live/courses_test.exs
defmodule StudentLive.CoursesTest do
  use StudentLive.DataCase, async: true
  use Oban.Testing, repo: StudentLive.Repo

  alias StudentLive.Courses
  alias StudentLive.Courses.Course
  alias StudentLive.Enrollments.Enrollment
  alias StudentLive.Workers.ProcessWaitlistWorker

  defp create_student(name) do
    # Adjust this according to your actual Student schema/fixture
    StudentLive.Repo.insert!(%StudentLive.Students.Student{name: name})
  end

  defp create_course(capacity) do
    Repo.insert!(%Course{
      title: "Elixir Basics",
      start_date: ~D[2026-09-01],
      end_date: ~D[2026-12-15],
      maximum_capacity: capacity,
      current_enrollment_count: 0
    })
  end

  describe "Course enrollment & waitlist processing" do
    test "correctly handles FIFO waitlisting and automatic promotion on deregistration" do
      # 1. Setup course with maximum capacity of 2
      course = create_course(2)

      student1 = create_student("Alice")
      student2 = create_student("Bob")
      student3 = create_student("Charlie") # Will be 1st waitlisted
      student4 = create_student("Diana")   # Will be 2nd waitlisted

      # 2. Enroll Students 1 and 2 -> Should both be :active
      assert %Enrollment{status: :active} = Courses.enroll_student(student1.id, course.id)
      assert %Enrollment{status: :active} = Courses.enroll_student(student2.id, course.id)

      # Verify course count updated
      updated_course = Repo.get!(Course, course.id)
      assert updated_course.current_enrollment_count == 2

      # 3. Enroll Students 3 and 4 -> Should both be :waitlisted
      assert %Enrollment{status: :waitlisted} = Courses.enroll_student(student3.id, course.id)
      # Artificial small sleep to ensure strictly distinct inserted_at microsecond timestamps
      Process.sleep(10)
      assert %Enrollment{status: :waitlisted} = Courses.enroll_student(student4.id, course.id)

      # Course count stays at 2 because new students are on waitlist
      assert Repo.get!(Course, course.id).current_enrollment_count == 2

      # 4. Deregister Student 1 (Active)
      assert {:ok, _} = Courses.deregister_student(student1.id, course.id)

      # Assert that an Oban job was enqueued for ProcessWaitlistWorker
      assert_enqueued(
        worker: ProcessWaitlistWorker,
        args: %{"course_id" => course.id}
      )

      # 5. Perform the Oban job synchronously in test mode
      assert :ok = drain_jobs(queue: :enrollments)

      # 6. Verify FIFO outcome:
      # - Student 3 (Charlie, oldest waitlisted) is promoted to :active
      # - Student 4 (Diana) remains :waitlisted
      # - Course count stays at 2
      assert %Enrollment{status: :active} = Repo.get_by(Enrollment, student_id: student3.id, course_id: course.id)
      assert %Enrollment{status: :waitlisted} = Repo.get_by(Enrollment, student_id: student4.id, course_id: course.id)
      assert Repo.get!(Course, course.id).current_enrollment_count == 2
    end
  end
end
