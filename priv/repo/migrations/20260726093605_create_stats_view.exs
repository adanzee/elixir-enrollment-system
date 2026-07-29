defmodule StudentLive.Repo.Migrations.CreateStatsView do
  use Ecto.Migration

  def change do
    execute """
    CREATE VIEW courses_with_stats AS
    SELECT
      c.*,
      COALESCE(COUNT(e.id), 0)::integer AS enrolled_count
    FROM courses c
    LEFT JOIN enrollments e ON e.course_id = c.id
    GROUP BY c.id;
    """,
    """
    DROP VIEW IF EXISTS courses_with_stats;
    """

  end
end
