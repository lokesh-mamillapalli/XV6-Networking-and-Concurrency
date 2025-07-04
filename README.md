# XV6-Networking-and-Concurrency
 The implementation is based on the specifications provided in [`mp2Questions.md`](./mp2Questions.md) and [`mp3Questions.md`](./mp3Questions.md).

 # Networking

### **Networking Task 1: Multiplayer Tic-Tac-Toe Game (15 points)**

#### **Overview**
- **Server Responsibilities**: 
  - Manage the game state (Tic-Tac-Toe board).
  - Handle communication between players.
  - Enforce game rules, including turn-taking and move validation.
  - Determine the winner or draw outcome.

- **Client Responsibilities**:
  - Allow players to send their moves to the server.
  - Display the board state and outcomes in a user-friendly format.
  - Notify the server of readiness and game continuation decisions.

---

#### **Game Rules and Flow**
1. **Initial Setup**:
   - The server initializes an empty 3x3 grid.
   - Players connect to the server. Once both are ready, Player 1 is assigned "X" and Player 2 is assigned "O".

2. **Gameplay**:
   - Players alternate turns. The server ensures proper turn order.
   - Moves specify a grid position (e.g., `row col` for top-left as `1 1`).
   - Invalid moves are rejected by the server, prompting the player to try again.
   - The server updates the board and broadcasts the new state to both clients.
   - Each client displays the updated board and receives instructions for the next turn.

3. **Winning and Drawing**:
   - Win conditions: Three matching symbols in a row, column, or diagonal.
   - Draw: All positions filled without a winner.
   - The server announces the result (e.g., "Player 1 Wins!", "It's a Draw!") and displays the final board.

4. **After the Game**:
   - Players decide if they want to replay.
   - If both agree, the server resets the board and starts a new game.
   - If either declines, both connections are terminated.

#### **Implementation**
- **TCP Version**:
  - Reliable communication between clients and server.
  - Ensure strict sequencing and proper flow control.

- **UDP Version**:
  - Use acknowledgments and retries to handle packet loss or out-of-order delivery.
  - Ensure game state consistency despite UDP's unreliability.

---

### **Networking Task 2: Simulated TCP Over UDP (15 points)**

#### **Functionalities**
1. **Data Sequencing**:
   - Split data into fixed-size chunks or a fixed number of chunks.
   - Each chunk includes:
     - Sequence number.
     - Total number of chunks.
   - Receiver reassembles the data in sequence and displays the complete text.

2. **Retransmissions**:
   - Sender waits for ACKs from the receiver.
   - If an ACK for a specific chunk is not received within 0.1 seconds, the sender retransmits that chunk.
   - Sender continues transmitting other chunks while waiting for acknowledgments (pipelining).
   - **Testing Retransmissions**: Simulate missing ACKs (e.g., skip every third ACK) to test the retransmission mechanism. Remove this simulation in the final submission.

---

#### **Implementation Notes**
- **Server and Client**:
  - Both act as senders and receivers to simulate bidirectional communication.
  - Use structs for packing and unpacking data chunks and ACKs.

- **Design Choices**:
  - **Threads**: Optional, can simplify handling simultaneous sending and receiving.
  - **Non-blocking Sockets**: Alternative for asynchronous behavior without threads.

#### **Expected Workflow**:
1. **Sender**:
   - Divides data into chunks.
   - Sends each chunk along with sequence number and total chunk count.
   - Tracks ACKs and retransmits missing chunks after a timeout.

2. **Receiver**:
   - Receives chunks and sends ACKs referencing the sequence numbers.
   - Reassembles data in sequence.
   - Skips ACKs (for testing retransmission) and comments out this feature in the final submission.

---

### **Deliverables**
- **Part A**: Multiplayer Tic-Tac-Toe game using both TCP and UDP.
- **Part B**: Simulated TCP functionalities over UDP, including data sequencing and retransmissions.
- **Submission Directory**: `<mini-project2-directory>/networks/partB`.

# XV6 

### **System Calls**

#### **1. Gotta count ‘em all** (`getSysCount` and `syscount`)
- **Goal:** Count the number of times a specific system call is executed by a process and its children during the execution of a command.  
- **How:**  
  - Implement `getSysCount(int mask)` to track syscall counts based on a bitmask.
  - Use `syscount <mask> <command> [args]` to run a command and count the specified syscall.
  - Output example:  
    ```
    PID <caller_pid> called <syscall_name> <n> times.
    ```

---

#### **2. Wake me up when my timer ends** (`sigalarm` and `sigreturn`)
- **Goal:** Add functionality to alert a process periodically during its CPU time consumption.
- **How:**  
  - Implement `sigalarm(interval, handler)` to register a user-space function `handler` to be called every `interval` CPU ticks.
  - Add `sigreturn()` to reset the process state after the handler is executed, resuming the program from where it was interrupted.

---

### **Scheduling Policies**

#### **1. Lottery-Based Scheduling (LBS)**  
- **Goal:** Assign CPU time slices randomly based on the number of tickets a process holds.  
- **How:**  
  - Add a system call `settickets(int number)` to set the number of tickets for a process.
  - Processes with the same tickets are prioritized based on arrival time (earlier processes win ties).
  - Child processes inherit parent tickets.
  - Only processes in the `RUNNABLE` state participate in the lottery.

---

#### **2. Multi-Level Feedback Queue (MLFQ)**  
- **Goal:** Implement a priority-based scheduler using four queues with decreasing priorities.  
- **How:**  
  - **Queue Priorities and Time Slices:**  
    - Queue 0: 1 tick  
    - Queue 1: 4 ticks  
    - Queue 2: 8 ticks  
    - Queue 3: 16 ticks  
  - Processes start in the highest priority queue (Queue 0).  
  - Preempt lower-priority processes if higher-priority ones arrive.  
  - Demote processes using their entire time slice to a lower-priority queue.  
  - Processes returning from I/O resume in the same queue.
  - Use round-robin within the lowest priority queue (Queue 3).
  - **Priority Boosting:**  
    - Every 48 ticks, reset all processes to Queue 0 to prevent starvation.

---

### **Additional Notes**
1. **Debugging with `procdump`:**  
   - Extend `procdump` to print the current status of processes, including tickets, queues, and states, for debugging scheduling behavior.

2. **Compilation with Scheduler Flag:**  
   - Use `make clean; make qemu SCHEDULER=<policy>` to compile with either `LBS` or `MLFQ` as the scheduling policy.

---

# Concurrency

### 1. LAZY Read-Write (25 marks)
**Objective:** Simulate a file manager's behavior under load, handling multiple user requests for reading, writing, and deleting files concurrently.

#### Key Concepts:
- **Concurrency Management:** Use threads, locks, condition variables, or semaphores to simulate real-time operations.
- **User Requests:** Each operation (READ, WRITE, DELETE) has a specific processing time and concurrency limits.
- **Cancellation:** Users may cancel requests if they are not processed within a specified time.

#### Input Format:
- Time taken for operations (r, w, d).
- Number of files (n), maximum concurrent users (c), and maximum wait time (T).
- User requests with ID, file number, operation, and request time.

#### Rules:
- LAZY waits for 1 second after receiving a request before processing.
- Multiple users can read simultaneously, but writing and deleting are exclusive operations.
- Requests can be declined if the file is invalid or deleted.

#### Output Requirements:
- Chronological logs of events, including request submissions, processing starts, cancellations, and completions.

---

### 2. LAZY Sort (35 marks)
**Objective:** Implement a distributed sorting mechanism that dynamically selects sorting algorithms based on the number of files.

#### Sorting Strategy:
- **Threshold-Based Decision:**
  - Use **Distributed Count Sort** for fewer than 42 files.
  - Use **Distributed Merge Sort** for 42 or more files.

#### Input Format:
- An integer indicating the total number of files.
- Each file's attributes (name, ID, timestamp) on separate lines.
- The column used for sorting (one of "Name", "ID", "Timestamp").

#### Output Requirements:
- The name of the sorting column.
- The sorted list of files with attributes in the original order, separated by spaces.

### Implementation Considerations:
- The sorting should be efficient, activating nodes only as needed to minimize resource usage.
- Ensure coordination between nodes for effective distributed sorting.

