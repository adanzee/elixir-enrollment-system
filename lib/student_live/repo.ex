defmodule StudentLive.Repo do
  use Ecto.Repo,
    otp_app: :student_live,
    adapter: Ecto.Adapters.Postgres
end
