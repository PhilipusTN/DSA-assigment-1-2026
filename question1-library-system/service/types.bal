


public type Status "AVAILABLE" | "LOANED_OUT" | "OCCUPIED" | "UNDER_MAINTENANCE" | "DISPOSED";


public type Component record {|
    string compId;
    string name;
    string description;
|};

public type ScheduleType "MAINTENANCE" | "BOOKING" | "SERVICING";


public type Schedule record {|
    string scheduleId;
    ScheduleType 'type;
    string dueDate;       
    string description;
|};

public type TaskStatus "PENDING" | "IN_PROGRESS" | "DONE";


public type Task record {|
    string taskId;
    string description;
    TaskStatus status = "PENDING";
|};

public type WorkOrderStatus "OPEN" | "IN_PROGRESS" | "CLOSED";


public type WorkOrder record {|
    string orderId;
    WorkOrderStatus status;
    string description;
    Task[] tasks = [];
|};


public type Asset record {|
    string assetTag;               
    string name;
    string description;
    string institution;
    string site;                   
    Status status;
    string dateAcquired;           
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};


public type Institution record {|
    string name;
    string[] sites = [];
|};


public type ErrorDetail record {|
    string message;
    string timestamp;
|};


public type LoanRequest record {|
    string borrower;
    string dueDate;      
|};


public type WorkOrderStatusUpdate record {|
    WorkOrderStatus status;
|};


public type TaskStatusUpdate record {|
    TaskStatus status;
|};
