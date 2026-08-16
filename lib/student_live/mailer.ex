defmodule StudentLive.Mailer do
  use Swoosh.Mailer, otp_app: :student_live

  def deliver_and_notify(%Swoosh.Email{} = email, student_id \\ nil) do
    case deliver(email) do
      {:ok, _result} = success ->
        if student_id do
          Phoenix.PubSub.broadcast(StudentLive.PubSub, "mailbox:#{student_id}", {:new_email, email})
        else
          Phoenix.PubSub.broadcast(StudentLive.PubSub, "mailbox:new_email", {:new_email, email})
        end

        success

      error ->
        error
    end
  end
end
