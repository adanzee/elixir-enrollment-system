defmodule StudentLive.Emails.StudentEmail do
  import Swoosh.Email

  @sender {"StudentLive Academy", "notifications@studentlive.com"}


  def student_registered(student) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Welcome to StudentLive!")
    |> text_body("Hi #{student.name},\n\nYour account has been created successfully. You can now explore courses and enroll.")
  end


  def enrollment_confirmed(student, course) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Confirmed: Enrollment for #{course.title}")
    |> text_body("Hi #{student.name},\n\nYou are enrolled in #{course.title}. View syllabus and assignments on your dashboard.")
  end


  def waitlist_joined(student, course) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Waitlisted: #{course.title}")
    |> text_body("Hi #{student.name},\n\n#{course.title} is currently at maximum capacity. You are placed on the waitlist.")
  end


  def student_deregistered(%StudentLive.Schemas.Student{} = student, %StudentLive.Schemas.Course{} = course) do
    new()
    |> to({student.name, student.email})
    |> from({"StudentLive Academy", "notifications@studentlive.com"})
    |> subject("Deregistered: #{course.title}")
    |> text_body("Hi #{student.name},\n\nYou have successfully deregistered from #{course.title}.")
  end


  def waitlist_promoted(student, course) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Spot Available: Enrolled in #{course.title}")
    |> text_body("Hi #{student.name},\n\nA spot opened up and your enrollment in #{course.title} is now active!")
  end

  def password_reset(student, reset_url) do
  new()
  |> to({student.name, student.email})
  |> from(@sender)
  |> subject("Reset your password")
  |> text_body("""
  Hi #{student.name},

  You requested a password reset.

  Reset your password here:
  #{reset_url}

  This link expires in 1 hour.

  If you didn't request this, you can ignore this email.
  """)
  |> html_body("""
  <h2>Reset your password</h2>

  <p>Hi #{student.name},</p>

  <p>You requested a password reset.</p>

  <p>
    <a href="#{reset_url}">Reset your password #{reset_url}</a>
  </p>

  <p>This link expires in 1 hour.</p>

  <p>If you didn't request this, you can ignore this email.</p>
  """)
end
end
