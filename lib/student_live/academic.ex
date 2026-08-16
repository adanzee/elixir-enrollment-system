defmodule StudentLive.Academic do
  import Ecto.Query, warn: false
  alias StudentLive.Repo
  alias StudentLive.Schemas.{Student, Course, Assignment, Enrollment, Submission}

  def get_course!(id) do
    Course
    |> Repo.get!(id)
    |> Repo.preload(:assignments)
  end

  def list_assignments_for_course(course_id) do
    Repo.all(from a in Assignment, where: a.course_id == ^course_id)
  end



  def get_student_by_email(email) when is_binary(email) do
    case Repo.get_by(Student, email: String.downcase(String.trim(email))) do
      nil ->
        {:error, :student_not_found}

      student ->
        preloaded_student =
          student
          |> Repo.preload(courses: :assignments, submissions: [])

        {:ok, preloaded_student}
    end
  end

  def get_student_by_id(id) when is_binary(id) do
    case Repo.get(Student, id) do
      nil ->
        {:error, :student_not_found}

      student ->
        {:ok, Repo.preload(student, submissions: [])}
    end
  end

  def enrolled?(student_id, course_id) when is_binary(student_id) and is_binary(course_id) do
    from(e in Enrollment, where: e.student_id == ^student_id and e.course_id == ^course_id)
    |> Repo.exists?()
  end

  def enroll_student(email, course_id) do
    today = Date.utc_today()

    Ecto.Multi.new()
    |> Ecto.Multi.run(:student, fn _repo, _ ->
      get_student_by_email(email)
    end)
    |> Ecto.Multi.run(:course_for_update, fn repo, _ ->

      query = from c in Course, where: c.id == ^course_id, lock: "FOR UPDATE"
      case repo.one(query) do
        nil -> {:error, :course_not_found}
        course -> {:ok, course}
      end
    end)
    |> Ecto.Multi.run(:validate_timeline, fn _repo, %{course_for_update: course} ->
      if Date.compare(today, course.start_date) == :lt do
        {:ok, true}
      else
        {:error, :course_already_started}
      end
    end)
    |> Ecto.Multi.run(:validate_capacity, fn repo, %{course_for_update: course} ->
      current_count = repo.aggregate(from(e in Enrollment, where: e.course_id == ^course.id), :count, :id)

      if current_count < course.capacity do
        {:ok, current_count}
      else
        {:error, :course_full}
      end
    end)
    |> Ecto.Multi.insert(:enrollment, fn %{student: student, course_for_update: course} ->
      Enrollment.changeset(%Enrollment{}, %{student_id: student.id, course_id: course.id})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{enrollment: enrollment}} -> {:ok, enrollment}
      {:error, :student, :student_not_found, _} -> {:error, "Student with this email does not exist."}
      {:error, :course_for_update, :course_not_found, _} -> {:error, "Course not found."}
      {:error, :validate_timeline, :course_already_started, _} -> {:error, "Cannot enroll: Course has already started."}
      {:error, :validate_capacity, :course_full, _} -> {:error, "Cannot enroll: Course capacity reached."}
      {:error, :enrollment, changeset, _} -> {:error, changeset}
    end
  end


  def unenroll_student(email, course_id) do
    today = Date.utc_today()

    Ecto.Multi.new()
    |> Ecto.Multi.run(:student, fn _repo, _ ->
      get_student_by_email(email)
    end)
    |> Ecto.Multi.run(:course, fn repo, _ ->
      case repo.get(Course, course_id) do
        nil -> {:error, :course_not_found}
        course -> {:ok, course}
      end
    end)
    |> Ecto.Multi.run(:validate_deregistration_timeline, fn _repo, %{course: course} ->
      if Date.compare(today, course.start_date) == :lt do
        {:ok, true}
      else
        {:error, :course_already_started}
      end
    end)
    |> Ecto.Multi.run(:enrollment, fn repo, %{student: student, course: course} ->
      query = from e in Enrollment, where: e.student_id == ^student.id and e.course_id == ^course.id
      case repo.one(query) do
        nil -> {:error, :not_enrolled}
        enrollment -> {:ok, enrollment}
      end
    end)
    |> Ecto.Multi.delete(:delete_enrollment, fn %{enrollment: enrollment} ->
      enrollment
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_enrollment: enrollment}} -> {:ok, enrollment}
      {:error, :student, :student_not_found, _} -> {:error, "Student with specified email not found."}
      {:error, :course, :course_not_found, _} -> {:error, "Target course not found."}
      {:error, :validate_deregistration_timeline, :course_already_started, _} -> {:error, "Deregistration failed: Course has already started."}
      {:error, :enrollment, :not_enrolled, _} -> {:error, "Student is not enrolled in this course."}
    end
  end

  def create_submission(email, assignment_id, file_path, original_filename) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:student, fn _repo, _ ->
      get_student_by_email(email)
    end)
    |> Ecto.Multi.run(:assignment, fn repo, _ ->
      case repo.get(Assignment, assignment_id) do
        nil -> {:error, :assignment_not_found}
        assignment -> {:ok, assignment}
      end
    end)
    |> Ecto.Multi.run(:verify_enrollment, fn repo, %{student: student, assignment: assignment} ->
      query = from e in Enrollment, where: e.student_id == ^student.id and e.course_id == ^assignment.course_id
      if repo.exists?(query) do
        {:ok, true}
      else
        {:error, :student_not_enrolled_in_course}
      end
    end)
    |> Ecto.Multi.insert(:submission, fn %{student: student, assignment: assignment} ->
      Submission.changeset(%Submission{}, %{
        student_id: student.id,
        assignment_id: assignment.id,
        file_path: file_path,
        original_filename: original_filename
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{submission: submission}} -> {:ok, submission}
      {:error, :student, _, _} -> {:error, "Student not found."}
      {:error, :assignment, _, _} -> {:error, "Assignment not found."}
      {:error, :verify_enrollment, _, _} -> {:error, "Submission rejected: Student is not enrolled in the course."}
      {:error, :submission, changeset, _} -> {:error, changeset}
    end
  end

  def get_submission!(id) do
    Submission
    |> Repo.get!(id)
    |> Repo.preload([:student, assignment: :course])
  end

  def list_submissions_for_student(student_id) do
    Repo.all(
      from s in Submission,
      where: s.student_id == ^student_id,
      preload: [assignment: :course]
    )
  end




end
