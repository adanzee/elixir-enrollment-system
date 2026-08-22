# Student Enrollment System

A student course enrollment system built with **Elixir, Phoenix, Phoenix LiveView, Ecto, PostgreSQL, Oban, and Swoosh**.

The system allows students to register, authenticate, browse courses, enroll in courses, join FIFO waitlists, deregister before a course starts, submit assignments, and receive email notifications through background jobs.

**Repository:** https://github.com/adanzee/elixir-enrollment-system

---

## Features

* 🔐 Student registration and authentication
* 📚 Course browsing and course details
* 🎓 Course enrollment
* ⏳ FIFO course waitlists
* 🚪 Course deregistration
* ⚡ Oban background job processing
* 📧 Asynchronous email delivery with Swoosh
* 📝 Assignment submission
* 👨‍🎓 Student dashboard
* 🗄️ PostgreSQL database
* 🔒 Transactional enrollment and concurrency handling
* 🖥️ Phoenix LiveView interface

---

## Tech Stack

| Technology       | Purpose              |
| ---------------- | -------------------- |
| Elixir           | Backend language     |
| Phoenix          | Web framework        |
| Phoenix LiveView | Interactive UI       |
| Ecto             | Database interaction |
| PostgreSQL       | Database             |
| Oban             | Background jobs      |
| Swoosh           | Email delivery       |
| Bcrypt           | Password hashing     |
| Tailwind CSS     | Styling              |
| esbuild          | Asset bundling       |
| Bandit           | HTTP server          |

---

## Requirements

Make sure you have:

* Elixir
* Erlang/OTP
* PostgreSQL
* Git

Verify your installation:

```bash
elixir --version
mix --version
psql --version
git --version
```

---

## Installation

Clone the repository:

```bash
git clone https://github.com/adanzee/elixir-enrollment-system.git
cd elixir-enrollment-system
```

Install dependencies and prepare the database:

```bash
mix setup
```

---

## Running the Application

Start Phoenix:

```bash
mix phx.server
```

Or:

```bash
iex -S mix phx.server
```

Open:

```text
http://localhost:4000
```

---

## Database Commands

```bash
mix ecto.create
mix ecto.migrate
mix ecto.reset
```

Or prepare everything with:

```bash
mix setup
```

---

## Testing

Run tests:

```bash
mix test
```

Run the complete precommit checks:

```bash
mix precommit
```

Format the project:

```bash
mix format
```

---

## Documentation

For detailed documentation, see:

* [Architecture](ARCHITECTURE.md)
* [Implemented Functionality](FUNCTIONALITY.md)

---

## Project Goals

This project was created to gain practical experience with:

* Phoenix and LiveView
* Ecto and PostgreSQL
* Authentication and sessions
* Database transactions
* Concurrency handling
* Course enrollment business logic
* FIFO waitlists
* Oban background workers
* Swoosh email delivery
* File uploads
* Phoenix application architecture

---

## Author

**Adan**

GitHub: https://github.com/adanzee/elixir-enrollment-system

---

## License

This project was created for learning and educational purposes.

