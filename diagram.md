``` mermaid

flowchart TB

    Start([Student Opens Portal]) --> BrowseCourses[Browse Course Catalog]

    %% ----------------------------------------------------
    subgraph Auth ["🔐 1. Authentication & Session Management"]
        BrowseCourses --> CheckAuth{Is Student Logged In?}
        
        CheckAuth -- No --> AuthPath{Account Status}
        AuthPath -- Existing Account --> AuthLogin[Enter Credentials]
        AuthPath -- New User --> AuthRegister[Register New Account]

        AuthLogin --> ValidLogin{Valid Password?}
        ValidLogin -- No --> ErrCreds[Show 'Invalid Credentials']
        ValidLogin -- Yes --> EstablishSession[Establish Session AuthN/AuthZ]

        AuthRegister --> RegisterCapacity{Is Course Open & Has Capacity?}
        RegisterCapacity -- Yes --> EstablishSession
        RegisterCapacity -- No / Capacity Full --> EnqueueOban
    end

    %% ----------------------------------------------------
    subgraph Enrollment ["📚 2. Course Enrollment & Capacity Engine"]
        EstablishSession --> CheckCourseState{Course Status}
        
        CheckCourseState -- Already Started --> ErrStarted[Block: Course Already Started]
        CheckCourseState -- Open & Not Started --> CheckCapacity{Seats Available?}

        CheckCapacity -- Yes --> DirectEnroll[Enroll Student Directly]
        CheckCapacity -- Full --> EnqueueOban[Hand Off to Oban Job]
    end

    %% ----------------------------------------------------
    subgraph ObanEngine ["⚡ 3. Oban Background Processing (Async FIFO Engine)"]
        EnqueueOban --> AddWaitlist[(Add Student to FIFO Waitlist)]
        
        TriggerOban[Trigger Oban Worker on Deregistration Event] --> DequeueFIFO{Next Student in FIFO Queue?}
        DequeueFIFO -- Yes --> AutoEnroll[Auto-Enroll Student & Send Notification]
        DequeueFIFO -- Queue Empty --> IdleState[Idle / Await Next Event]
    end

    %% ----------------------------------------------------
    subgraph Dashboard ["🎓 4. Student Dashboard & Actions"]
        DirectEnroll --> StudentDash[Access Dashboard]
        AutoEnroll --> StudentDash

        StudentDash --> ViewContent[View Course Outlines & Assignments]
        StudentDash --> UploadAssignment[Upload Assignment]
        
        %% Navigation Guard Rule
        StudentDash --> NavBack{Navigate Back / Refresh?}
        NavBack -- Soft Navigation --> MaintainSession[Maintain Active Session]
        MaintainSession --> StudentDash
        NavBack -- Explicit Logout --> TerminateSession[Destroy Session & Auth Tokens]
        TerminateSession --> BrowseCourses
    end

    %% ----------------------------------------------------
    subgraph Deregistration ["🚪 5. Course Deregistration"]
        StudentDash --> DeregReq[Request Deregistration]
        DeregReq --> CheckStartedDereg{Has Course Started?}
        
        CheckStartedDereg -- Yes --> ErrNoDereg[Block: Cannot Deregister After Course Starts]
        CheckStartedDereg -- No --> RemoveStudent[Remove Student from Course]
        RemoveStudent --> TriggerOban
    end

    %% ----------------------------------------------------
    %% Styling Definitions & Assignments
    classDef primary fill:#2563EB,stroke:#1D4ED8,color:#FFFFFF,stroke-width:1.5px;
    classDef success fill:#059669,stroke:#047857,color:#FFFFFF,stroke-width:1.5px;
    classDef warning fill:#D97706,stroke:#B45309,color:#FFFFFF,stroke-width:1.5px;
    classDef danger fill:#DC2626,stroke:#B91C1C,color:#FFFFFF,stroke-width:1.5px;
    classDef neutral fill:#4B5563,stroke:#374151,color:#FFFFFF,stroke-width:1.5px;

    class Start,IdleState,TerminateSession neutral;
    class BrowseCourses,AuthLogin,AuthRegister,StudentDash,ViewContent,UploadAssignment,DeregReq,TriggerOban primary;
    class CheckAuth,AuthPath,ValidLogin,RegisterCapacity,CheckCourseState,CheckCapacity,EnqueueOban,AddWaitlist,DequeueFIFO,NavBack,CheckStartedDereg warning;
    class EstablishSession,DirectEnroll,AutoEnroll,MaintainSession,RemoveStudent success;
    class ErrCreds,ErrStarted,ErrNoDereg danger;

    
    ```