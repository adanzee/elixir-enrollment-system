# System Architecture

This document describes the architecture and major workflows of the Student Enrollment System.

---

## Application Architecture

The application follows the standard Phoenix architecture:

```text
                         Browser
                            │
                            ▼
                    ┌───────────────┐
                    │ Phoenix Router│
                    └───────┬───────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
           LiveViews                Controllers
                │                       │
                └───────────┬───────────┘
                            ▼
                    Business Logic
                            │
                            ▼
                          Ecto
                            │
                            ▼
                       PostgreSQL

                            │
                            ▼
                           Oban
                       ┌────┴────┐
                       ▼         ▼
                  Waitlist     Mailer
                   Worker      Worker
                       │         │
                       ▼         ▼
                  Enrollment   Swoosh
```

---

## Core Data Model

The main entities are:

```text
Student
   │
   │ has many
   ▼
Enrollment
   │
   │ belongs to
   ▼
Course
   │
   └──────────► Assignment
                    │
                    ▼
                Submission
```

### Student

Represents a registered student.

A student can have multiple course enrollments.

### Course

Contains:

* Title
* Description
* Course outline
* Start date
* End date
* Maximum capacity

### Enrollment

Connects students to courses.

An enrollment can have states such as:

```text
active
waitlisted
```

### Assignment

Represents an assignment belonging to a course.

### Submission

Represents a student's submitted assignment.

---

# Enrollment Architecture

Enrollment is a concurrency-sensitive operation because several students can attempt to take the last available seat simultaneously.

The system uses database transactions and row-level locking.

```text
Begin Transaction
       │
       ▼
Lock Course
       │
       ▼
Count Active Enrollments
       │
       ▼
Check Capacity
       │
   ┌───┴────┐
   ▼        ▼
Available  Full
   │        │
   ▼        ▼
Active   Waitlisted
   │        │
   └───┬────┘
       ▼
Commit Transaction
```

This prevents multiple concurrent requests from incorrectly consuming the same seat.

---

# FIFO Waitlist Architecture

When a course reaches capacity, new students are placed into a waitlist.

Example:

```text
Course Capacity: 2

Student A → ACTIVE
Student B → ACTIVE

Student C → WAITLISTED #1
Student D → WAITLISTED #2
Student E → WAITLISTED #3
```

When Student A deregisters:

```text
Student A → Removed
     │
     ▼
Oban Waitlist Job
     │
     ▼
Student C → ACTIVE
     │
     ▼
Student D → WAITLISTED #1
Student E → WAITLISTED #2
```

The earliest waitlisted student is promoted first.

---

# Background Job Architecture

Oban is used for asynchronous processing.

There are two major background-job flows.

## Waitlist Job

```text
Student Deregisters
        │
        ▼
Seat Released
        │
        ▼
Oban Waitlist Job
        │
        ▼
Find First Waitlisted Student
        │
        ▼
Promote Student
        │
        ▼
Queue Notification
```

## Mailer Job

```text
Application Event
       │
       ▼
Create Mailer Job
       │
       ▼
Oban Queue
       │
       ▼
Mailer Worker
       │
       ▼
Swoosh
       │
       ▼
Email Delivery
```

Keeping email delivery in a background job prevents the user-facing operation from waiting for an email provider.

---

# Complete Enrollment Lifecycle

```text
                    Student
                       │
                       ▼
                  Login/Register
                       │
                       ▼
                  Browse Courses
                       │
                       ▼
                 Select Course
                       │
                       ▼
                Check Capacity
                  /         \
                 /           \
          Available           Full
              │                │
              ▼                ▼
           ACTIVE         WAITLISTED
              │                │
              ▼                │
          Dashboard            │
              │                │
              ▼                │
         Assignments           │
              │                │
              ▼                │
          Submission           │
                               │
                               ▼
                    Active Student Leaves
                               │
                               ▼
                         Oban Worker
                               │
                               ▼
                    Next Student Promoted
                               │
                               ▼
                         Mailer Worker
                               │
                               ▼
                            Swoosh
                               │
                               ▼
                         Email Sent
```

---

# Authentication Architecture

```text
Browser
   │
   ▼
LoginLive
   │
   ▼
StudentSessionController
   │
   ▼
Validate Credentials
   │
   ├───────────────┐
   │               │
 Invalid          Valid
   │               │
   ▼               ▼
Error          Create Session
                   │
                   ▼
               Dashboard
```

Authentication uses sessions to identify the currently logged-in student.

---

# Student Application Flow

```text
/login
   │
   ▼
/dashboard
   │
   ▼
/courses
   │
   ▼
/courses/:id
   │
   ▼
/assignments/:id
   │
   ▼
Assignment Submission
```

---

# Architectural Principles

The project applies several backend design principles:

### Separation of concerns

UI, business logic, database operations, and background jobs are kept separate.

### Database as source of truth

Enrollment state is stored in PostgreSQL rather than being maintained only in the UI.

### Transactions

Enrollment operations use transactions where multiple database operations must succeed together.

### Concurrency control

Course locking is used when checking capacity and creating enrollments.

### Asynchronous processing

Tasks that do not need to block the user's request are handled through Oban.

### Background email delivery

Swoosh is integrated with background jobs so email delivery does not block enrollment operations.
