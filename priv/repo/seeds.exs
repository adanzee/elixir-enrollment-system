alias StudentLive.Repo
alias StudentLive.Schemas.Student
alias StudentLive.Schemas.{Course, Assignment}

# to clean any existing data
Repo.delete_all(StudentLive.Schemas.Submission)
Repo.delete_all(StudentLive.Schemas.Enrollment)
Repo.delete_all(Assignment)
Repo.delete_all(Course)
Repo.delete_all(Student)

#  Students
students_data = [
  %{name: "Alice Smith", email: "alice@example.com"},
  %{name: "Bob Jones", email: "bob@example.com"},
  %{name: "Charlie Brown", email: "charlie@example.com"}
]

students =
  Enum.map(students_data, fn attrs ->
    %Student{}
    |> Student.changeset(attrs)
    |> Repo.insert!()
  end)

# to generate today's date
today = Date.utc_today()

# Courses
courses_data = [
  %{
    title: "CS101: Introduction to Phoenix LiveView",
    description: "Learn how to build real-time, interactive web applications without leaving Elixir.",
    outline_pdf_path: "/uploads/database_outline.pdf",
    start_date: Date.add(today, 14),
    end_date: Date.add(today, 20),
    maximum_capacity: 30,
    current_enrollment_count: 0
  },
  %{
    title: "CS201: Advanced Elixir and Ecto",
    description: "Deep dive into concurrency, GenServer patterns, transactions, and complex database schemas.",
    outline_pdf_path: "/uploads/web_engineering_outline.pdf",
    start_date: Date.add(today, 7),
    end_date: Date.add(today, 15),
    maximum_capacity: 2,
    current_enrollment_count: 0
  },
  %{
    title: "CS301: Functional System Architecture",
    description: "Architecting large-scale systems with Elixir OTP and distributed nodes.",
    outline_pdf_path: "/uploads/programming_outline.pdf",
    start_date: Date.add(today, -10),
    end_date: Date.add(today, 30),
    maximum_capacity: 25,
    current_enrollment_count: 0
  }
]

courses =
  Enum.map(courses_data, fn attrs ->
    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert!()
  end)

# 4. Seed Assignments
[cs101, cs201, cs301] = courses

assignments_data = [
  #Assignments
  %{
    title: "Assignment 1: LiveView Components & Form",
    description: "Build a single-page LiveView form that handles basic user validation and submit handling.",
    maximum_submissions_per_student: 2,
    course_id: cs101.id
  },
  %{
    title: "Assignment 2: File Uploads & Progress",
    description: "Implement LiveView upload with entry consuming and local storage integration.",
    maximum_submissions_per_student: 3,
    course_id: cs101.id
  },

  #Assignments
  %{
    title: "Assignment 1: Complex Ecto Queries & Transactions",
    description: "Write Ecto queries using multi-step Repo.transaction blocks and custom error handling.",
    maximum_submissions_per_student: 1,
    course_id: cs201.id
  },

  #Assignments
  %{
    title: "Final Project: Distributed Node Setup",
    description: "Submit your architectural design document for a distributed Erlang cluster.",
    maximum_submissions_per_student: 2,
    course_id: cs301.id
  }
]

Enum.each(assignments_data, fn attrs ->
  %Assignment{}
  |> Assignment.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("Successfully seeded #{length(students)} students, #{length(courses)} courses, and #{length(assignments_data)} assignments.")
