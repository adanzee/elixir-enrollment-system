defmodule StudentLive.Emails.StudentEmail do
  import Swoosh.Email

  @sender {"StudentLive Academy", "notifications@studentlive.com"}

  # 1. New User Registration
  def student_registered(student) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Welcome to StudentLive!")
    |> text_body("Hi #{student.name},\n\nYour account has been created successfully. You can now explore courses and enroll.")
  end

  # 2. Course Enrollment (Active)
  def enrollment_confirmed(student, course) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Confirmed: Enrollment for #{course.title}")
    |> text_body("Hi #{student.name},\n\nYou are enrolled in #{course.title}. View syllabus and assignments on your dashboard.")
  end

  # 3. Waitlist Confirmation
  def waitlist_joined(student, course) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Waitlisted: #{course.title}")
    |> text_body("Hi #{student.name},\n\n#{course.title} is currently at maximum capacity. You are placed on the waitlist.")
  end

  # 4. Deregistration / Drop Confirmation
# lib/student_live/emails/student_email.ex
  def student_deregistered(%StudentLive.Schemas.Student{} = student, %StudentLive.Schemas.Course{} = course) do
    new()
    |> to({student.name, student.email})
    |> from({"StudentLive Academy", "notifications@studentlive.com"})
    |> subject("Deregistered: #{course.title}")
    |> html_body("""
    <div style="background-color: #0d1322; color: #cbd5e1; padding: 24px; font-family: sans-serif;">
      <div style="background-color: #151c2e; border: 1px solid #1e293b; border-radius: 12px; padding: 24px;">
        <h2 style="color: #ffffff; margin-top: 0;">Course Deregistered</h2>
        <p>Hi <strong style="color: #ffffff;">#{student.name}</strong>,</p>
        <p>You have successfully deregistered from <strong style="color: #ffffff;">#{course.title}</strong>.</p>
      </div>
    </div>
    """)
    |> text_body("Hi #{student.name},\n\nYou have successfully deregistered from #{course.title}.")
  end

  # 5. Promoted from Waitlist to Active
  def waitlist_promoted(student, course) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Spot Available: Enrolled in #{course.title}")
    |> text_body("Hi #{student.name},\n\nA spot opened up and your enrollment in #{course.title} is now active!")
  end
end
