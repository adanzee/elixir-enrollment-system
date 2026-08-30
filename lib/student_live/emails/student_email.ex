defmodule StudentLive.Emails.StudentEmail do
  import Swoosh.Email

  @sender {"StudentLive Academy", "notifications@studentlive.com"}

  def student_registered(student) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Welcome to StudentLive!")
    |> text_body("""
    Hi #{student.name},

    Your account has been created successfully.

    You can now explore courses and enroll in the courses you're interested in.

    Welcome to StudentLive Academy!
    """)
    |> html_body("""
    #{email_template(
      "Welcome to StudentLive!",
      """
      <p>Hi <strong>#{student.name}</strong>,</p>

      <p>
        Your account has been created successfully.
        You can now explore our courses and enroll in the ones
        you're interested in.
      </p>

      <div style="margin: 28px 0; padding: 18px; background-color: #0d1322; border-radius: 8px; border: 1px solid #263149;">
        <p style="margin: 0; color: #cbd5e1; font-size: 14px;">
          Your StudentLive Academy account is ready to go.
        </p>
      </div>

      <p>
        We're glad to have you with us.
      </p>
      """
    )}
    """)
  end


  def enrollment_confirmed(student, course) do
    course_url = course_url(course)

    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Confirmed: Enrollment for #{course.title}")
    |> text_body("""
    Hi #{student.name},

    Your enrollment in #{course.title} has been confirmed.

    Access your resources here:
    - Course Overview: #{course_url}
    """)
    |> html_body("""
    #{email_template(
      "Enrollment Confirmed",
      """
      <p>Hi <strong>#{student.name}</strong>,</p>

      <p>
        Your enrollment has been successfully confirmed.
      </p>

      <div style="margin: 28px 0; padding: 20px; background-color: #0d1322; border-radius: 10px; border: 1px solid #263149;">
        <p style="margin: 0 0 8px 0; color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">
          Course
        </p>

        <p style="margin: 0; color: #ffffff; font-size: 18px; font-weight: bold;">
          #{course.title}
        </p>
      </div>

      <p>
        You can now access the full course dashboard or jump straight to the syllabus and assignments outline below:
      </p>


      <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="margin: 32px auto 16px auto; width: 100%;">
        <tr>
          <td align="center">
            <table role="presentation" border="0" cellpadding="0" cellspacing="0">
              <tr>
                <td style="padding: 0 8px 12px 8px;">
                  <a
                    href="#{course_url}"
                    target="_blank"
                    style="
                      display: inline-block;
                      padding: 12px 22px;
                      background-color: #00a878;
                      color: #ffffff;
                      text-decoration: none;
                      border-radius: 8px;
                      font-size: 14px;
                      font-weight: bold;
                    "
                  >
                    View Course
                  </a>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
      """
    )}
    """)
  end

  def waitlist_joined(student, course) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Waitlisted: #{course.title}")
    |> text_body("""
    Hi #{student.name},

    #{course.title} is currently at maximum capacity.

    You have been placed on the waitlist and will be notified if a spot becomes available.
    """)
    |> html_body("""
    #{email_template(
      "You've Been Waitlisted",
      """
      <p>Hi <strong>#{student.name}</strong>,</p>

      <p>
        The course you're trying to enroll in is currently at
        maximum capacity.
      </p>

      <div style="margin: 28px 0; padding: 20px; background-color: #0d1322; border-radius: 10px; border: 1px solid #263149;">
        <p style="margin: 0 0 8px 0; color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">
          Course
        </p>

        <p style="margin: 0; color: #ffffff; font-size: 18px; font-weight: bold;">
          #{course.title}
        </p>

        <p style="margin: 12px 0 0 0; color: #fbbf24; font-size: 13px;">
          You are currently on the waitlist.
        </p>
      </div>

      <p>
        Don't worry. If a spot becomes available,
        you'll be notified automatically.
      </p>
      """
    )}
    """)
  end



  def student_deregistered(
        %StudentLive.Schemas.Student{} = student,
        %StudentLive.Schemas.Course{} = course
      ) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Deregistered: #{course.title}")
    |> text_body("""
    Hi #{student.name},

    You have successfully deregistered from #{course.title}.
    """)
    |> html_body("""
    #{email_template(
      "Enrollment Cancelled",
      """
      <p>Hi <strong>#{student.name}</strong>,</p>

      <p>
        Your enrollment has been successfully cancelled.
      </p>

      <div style="margin: 28px 0; padding: 20px; background-color: #0d1322; border-radius: 10px; border: 1px solid #263149;">
        <p style="margin: 0 0 8px 0; color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">
          Course
        </p>

        <p style="margin: 0; color: #ffffff; font-size: 18px; font-weight: bold;">
          #{course.title}
        </p>
      </div>

      <p>
        If you change your mind, you can enroll again if the course
        is still accepting students.
      </p>
      """
    )}
    """)
  end


  def waitlist_promoted(student, course) do
    course_url = course_url(course)

    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Spot Available: Enrolled in #{course.title}")
    |> text_body("""
    Hi #{student.name},

    A spot has opened up and your enrollment in #{course.title} is now active!

    Access the course: #{course_url}
    """)
    |> html_body("""
    #{email_template(
      "You're In! 🎉",
      """
      <p>Hi <strong>#{student.name}</strong>,</p>

      <p>
        Great news! A spot has opened up and your enrollment
        is now active.
      </p>

      <div style="margin: 28px 0; padding: 20px; background-color: #0d1322; border-radius: 10px; border: 1px solid #263149;">
        <p style="margin: 0 0 8px 0; color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">
          Course
        </p>

        <p style="margin: 0; color: #ffffff; font-size: 18px; font-weight: bold;">
          #{course.title}
        </p>

        <p style="margin: 12px 0 0 0; color: #00a878; font-size: 13px; font-weight: bold;">
          Enrollment Active
        </p>
      </div>

      <p>
        You can now access the course, syllabus, and assignments
        from your StudentLive dashboard.
      </p>

      <div style="margin: 30px 0; text-align: center;">
        <a
          href="#{course_url}"
          style="
            display: inline-block;
            padding: 12px 24px;
            background-color: #00a878;
            color: #ffffff;
            text-decoration: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: bold;
          "
        >
          View Course
        </a>
      </div>
      """
    )}
    """)
  end


  def password_reset(student, reset_url) do
    new()
    |> to({student.name, student.email})
    |> from(@sender)
    |> subject("Reset your password")
    |> text_body("""
    Hi #{student.name},

    You requested a password reset for your StudentLive account.

    Reset your password here:
    #{reset_url}

    This link expires in 1 hour.

    If you didn't request this, you can safely ignore this email.
    """)
    |> html_body("""
    #{email_template(
      "Reset Your Password",
      """
      <p>Hi <strong>#{student.name}</strong>,</p>

      <p>
        We received a request to reset the password for your
        StudentLive Academy account.
      </p>

      <div style="margin: 30px 0; text-align: center;">
        <a
          href="#{reset_url}"
          style="
            display: inline-block;
            padding: 12px 24px;
            background-color: #00a878;
            color: #ffffff;
            text-decoration: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: bold;
          "
        >
          Reset Your Password
        </a>
      </div>

      <div style="margin: 24px 0; padding: 16px; background-color: #0d1322; border-radius: 8px; border: 1px solid #263149;">
        <p style="margin: 0; color: #94a3b8; font-size: 12px;">
          This password reset link will expire in <strong style="color: #cbd5e1;">1 hour</strong>.
        </p>
      </div>

      <p style="font-size: 13px; color: #94a3b8;">
        If you didn't request a password reset, you can safely ignore
        this email.
      </p>
      """
    )}
    """)
  end



  defp email_template(title, content) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{title}</title>
      </head>

      <body style="
        margin: 0;
        padding: 0;
        background-color: #0d1322;
        font-family: Arial, Helvetica, sans-serif;
        color: #cbd5e1;
      ">
        <div style="
          width: 100%;
          padding: 40px 0;
          background-color: #0d1322;
        ">
          <div style="
            max-width: 600px;
            margin: 0 auto;
            background-color: #151c2e;
            border: 1px solid #263149;
            border-radius: 14px;
            overflow: hidden;
          ">
            <!-- Header -->
            <div style="
              padding: 24px 30px;
              background-color: #101726;
              border-bottom: 1px solid #263149;
            ">
              <div style="
                font-size: 20px;
                font-weight: bold;
                color: #ffffff;
              ">
                StudentLive
              </div>

              <div style="
                margin-top: 4px;
                font-size: 11px;
                color: #00a878;
                text-transform: uppercase;
                letter-spacing: 1px;
              ">
                Academy
              </div>
            </div>


            <div style="
              padding: 32px 30px;
            ">
              <h1 style="
                margin: 0 0 22px 0;
                color: #ffffff;
                font-size: 22px;
                line-height: 1.3;
              ">
                #{title}
              </h1>

              <div style="
                color: #cbd5e1;
                font-size: 14px;
                line-height: 1.7;
              ">
                #{content}
              </div>
            </div>

            <div style="
              padding: 20px 30px;
              background-color: #101726;
              border-top: 1px solid #263149;
            ">
              <p style="
                margin: 0;
                color: #64748b;
                font-size: 11px;
                line-height: 1.6;
              ">
               Please do not reply to this email.
              </p>

              <p style="
                margin: 8px 0 0 0;
                color: #475569;
                font-size: 11px;
              ">
                © StudentLive Academy
              </p>
            </div>
          </div>
        </div>
      </body>
    </html>
    """
  end

    defp course_url(course) do
    base_url = Application.get_env(:student_live, :base_url)

    "#{base_url}/courses/#{course.id}"
    end

end
