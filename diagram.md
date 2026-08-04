``` mermaid
flowchart TD
    A[Student opens Course List] --> B[Click View & Enroll]
    B --> C[Enter Email]
    C --> D{Student Exists?}
    D -->|No| E[Create Student]
    D -->|Yes| F[Find Existing Student]
    E --> G[Check Enrollment]
    F --> G
    G --> H{Already Enrolled?}
    H -->|Yes| I{Enrollment Status}
    I -->|Waitlisted| K[Show Waitlist Position]
    I -->|Active| J[Show Course Outline & Assignments]
    H -->|No| L[Check Course Capacity]
    L --> M{Seats Available?}
    M -->|No| O[Create Enrollment Status: Waitlisted]
    M -->|Yes| N[Create Enrollment Status: Active]
    N --> J

    subgraph WL [waitlist]
        O --> P[Waitlist Queue FIFO]
        P --> Q[Student waits]
        Q --> R[Existing Student Deregisters]
        R --> S[Process Waitlist Worker]
        S --> T[Find Oldest Waitlisted Student]
        T --> U[Update Status Waitlisted → Active]
    end

    U --> J
```