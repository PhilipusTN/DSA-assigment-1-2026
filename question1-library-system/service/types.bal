// ==========================================================================
// Data model for the Distributed Library and Resource Management System
// ==========================================================================

// Lifecycle status of any asset (book, laptop, thin client, lab, room, ...)
public type Status "AVAILABLE" | "LOANED_OUT" | "OCCUPIED" | "UNDER_MAINTENANCE" | "DISPOSED";

// A sub-part of a complex asset, e.g. the motor inside a 3D printer.
public type Component record {|
    string compId;
    string name;
    string description;
|};

public type ScheduleType "MAINTENANCE" | "BOOKING" | "SERVICING";

// A booking / servicing schedule entry attached to an asset.
public type Schedule record {|
    string scheduleId;
    ScheduleType 'type;
    string dueDate;        // ISO-8601 date, e.g. "2026-09-01"
    string description;
|};

public type TaskStatus "PENDING" | "IN_PROGRESS" | "DONE";

// A sub-task inside a work order, e.g. "replace screen".
public type Task record {|
    string taskId;
    string description;
    TaskStatus status = "PENDING";
|};

public type WorkOrderStatus "OPEN" | "IN_PROGRESS" | "CLOSED";

// A fault/repair ticket raised against an asset.
public type WorkOrder record {|
    string orderId;
    WorkOrderStatus status;
    string description;
    Task[] tasks = [];
|};

// The core resource record: a book, laptop, thin client, lab or meeting room.
public type Asset record {|
    string assetTag;               // unique identifier, e.g. "NUST-LIB-3DP-001"
    string name;
    string description;
    string institution;
    string site;                   // campus / site within the institution
    Status status;
    string dateAcquired;           // ISO-8601 date
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};

// An institution registered on the platform (e.g. NUST, UNAM).
public type Institution record {|
    string name;
    string[] sites = [];
|};

// Generic error payload returned on 4xx/5xx responses.
public type ErrorDetail record {|
    string message;
    string timestamp;
|};

// Payload used to loan an asset or book a room/lab.
public type LoanRequest record {|
    string borrower;
    string dueDate;       // when the item/room must be returned/vacated
|};

// Payload used to update just the status of a work order.
public type WorkOrderStatusUpdate record {|
    WorkOrderStatus status;
|};

// Payload used to update just the status of a task inside a work order.
public type TaskStatusUpdate record {|
    TaskStatus status;
|};
