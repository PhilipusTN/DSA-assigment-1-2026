import ballerina/http;
import ballerina/io;

final http:Client libraryClient = check new ("http://localhost:8080/library");

public function main() returns error? {
    boolean running = true;
    while running {
        io:println("\n================ Library & Resource Management Client ================");
        io:println(" 1. Global View        — list every asset across the ministry");
        io:println(" 2. Campus View        — filter assets by institution / site");
        io:println(" 3. Loan / Book asset  — loan an item or book a room/lab");
        io:println(" 4. Return asset");
        io:println(" 5. Overdue Dashboard  — assets past their due date");
        io:println(" 6. Register new asset");
        io:println(" 7. Schedule Manager   — add/remove a servicing schedule");
        io:println(" 8. Manage institutions");
        io:println(" 9. Work orders        — open/update/close, add tasks");
        io:println(" 0. Exit");
        io:print("Select option: ");
        string choice = io:readln().trim();

        error? result = ();
        if choice == "1" {
            result = globalView();
        } else if choice == "2" {
            result = campusView();
        } else if choice == "3" {
            result = loanOrBook();
        } else if choice == "4" {
            result = returnAsset();
        } else if choice == "5" {
            result = overdueDashboard();
        } else if choice == "6" {
            result = registerAsset();
        } else if choice == "7" {
            result = scheduleManager();
        } else if choice == "8" {
            result = manageInstitutions();
        } else if choice == "9" {
            result = workOrders();
        } else if choice == "0" {
            running = false;
            continue;
        } else {
            io:println("Invalid option, try again.");
            continue;
        }

        if result is error {
            io:println("⚠ Error: " + result.message());
        }
    }
    io:println("Goodbye!");
}

// ---------------------------------------------------------------------
// 1. Global View
// ---------------------------------------------------------------------
function globalView() returns error? {
    json response = check libraryClient->get("/assets");
    printAssetList(response);
}

// ---------------------------------------------------------------------
// 2. Campus View
// ---------------------------------------------------------------------
function campusView() returns error? {
    io:print("Institution: ");
    string institution = io:readln().trim();
    io:print("Site/campus (leave blank for all sites at this institution): ");
    string site = io:readln().trim();

    json response;
    if site == "" {
        response = check libraryClient->get(
            string `/institutions/${institution}/assets`);
    } else {
        response = check libraryClient->get(
            string `/institutions/${institution}/sites/${site}/assets`);
    }
    printAssetList(response);
}

// ---------------------------------------------------------------------
// 3. Loan / Book
// ---------------------------------------------------------------------
function loanOrBook() returns error? {
    io:print("Asset tag to loan/book: ");
    string tag = io:readln().trim();
    io:print("Borrower / occupant name: ");
    string borrower = io:readln().trim();
    io:print("Due date (YYYY-MM-DD): ");
    string dueDate = io:readln().trim();

    json payload = {borrower: borrower, dueDate: dueDate};
    http:Response resp = check libraryClient->post(string `/assets/${tag}/loan`, payload);
    check printResponse(resp, "Asset loaned/booked successfully.");
}

// ---------------------------------------------------------------------
// 4. Return
// ---------------------------------------------------------------------
function returnAsset() returns error? {
    io:print("Asset tag to return: ");
    string tag = io:readln().trim();
    http:Response resp = check libraryClient->post(string `/assets/${tag}/return`, {});
    check printResponse(resp, "Asset returned — now AVAILABLE.");
}

// ---------------------------------------------------------------------
// 5. Overdue Dashboard
// ---------------------------------------------------------------------
function overdueDashboard() returns error? {
    json response = check libraryClient->get("/assets/overdue");
    io:println("\n--- Overdue Assets ---");
    printAssetList(response);
}

// ---------------------------------------------------------------------
// 6. Register a new asset
// ---------------------------------------------------------------------
function registerAsset() returns error? {
    io:print("Asset tag (unique): ");
    string tag = io:readln().trim();
    io:print("Name: ");
    string name = io:readln().trim();
    io:print("Description: ");
    string description = io:readln().trim();
    io:print("Institution: ");
    string institution = io:readln().trim();
    io:print("Site/campus: ");
    string site = io:readln().trim();
    io:print("Date acquired (YYYY-MM-DD): ");
    string dateAcquired = io:readln().trim();

    json payload = {
        assetTag: tag,
        name: name,
        description: description,
        institution: institution,
        site: site,
        status: "AVAILABLE",
        dateAcquired: dateAcquired,
        components: [],
        schedules: [],
        workOrders: []
    };
    http:Response resp = check libraryClient->post("/assets", payload);
    check printResponse(resp, "Asset registered.");
}

// ---------------------------------------------------------------------
// 7. Schedule Manager
// ---------------------------------------------------------------------
function scheduleManager() returns error? {
    io:print("Asset tag: ");
    string tag = io:readln().trim();
    io:println("1. Add schedule   2. Remove schedule   3. View schedules");
    io:print("Choice: ");
    string choice = io:readln().trim();

    if choice == "1" {
        io:print("Schedule id: ");
        string id = io:readln().trim();
        io:print("Type (MAINTENANCE/BOOKING/SERVICING): ");
        string sType = io:readln().trim();
        io:print("Due date (YYYY-MM-DD): ");
        string dueDate = io:readln().trim();
        io:print("Description: ");
        string desc = io:readln().trim();

        json payload = {scheduleId: id, 'type: sType, dueDate: dueDate, description: desc};
        http:Response resp = check libraryClient->post(string `/assets/${tag}/schedules`, payload);
        check printResponse(resp, "Schedule added.");
    } else if choice == "2" {
        io:print("Schedule id to remove: ");
        string id = io:readln().trim();
        http:Response resp = check libraryClient->delete(string `/assets/${tag}/schedules/${id}`);
        check printResponse(resp, "Schedule removed.");
    } else if choice == "3" {
        json response = check libraryClient->get(string `/assets/${tag}/schedules`);
        io:println(response.toJsonString());
    } else {
        io:println("Invalid choice.");
    }
}

// ---------------------------------------------------------------------
// 8. Manage institutions
// ---------------------------------------------------------------------
function manageInstitutions() returns error? {
    io:println("1. List institutions   2. Add institution   3. Remove institution");
    io:print("Choice: ");
    string choice = io:readln().trim();

    if choice == "1" {
        json response = check libraryClient->get("/institutions");
        io:println(response.toJsonString());
    } else if choice == "2" {
        io:print("Institution name: ");
        string name = io:readln().trim();
        json payload = {name: name, sites: []};
        http:Response resp = check libraryClient->post("/institutions", payload);
        check printResponse(resp, "Institution added.");
    } else if choice == "3" {
        io:print("Institution name to remove: ");
        string name = io:readln().trim();
        http:Response resp = check libraryClient->delete(string `/institutions/${name}`);
        check printResponse(resp, "Institution removed.");
    } else {
        io:println("Invalid choice.");
    }
}

// ---------------------------------------------------------------------
// 9. Work orders
// ---------------------------------------------------------------------
function workOrders() returns error? {
    io:print("Asset tag: ");
    string tag = io:readln().trim();
    io:println("1. Open work order   2. Update status   3. Add task   4. View work orders");
    io:print("Choice: ");
    string choice = io:readln().trim();

    if choice == "1" {
        io:print("Order id: ");
        string id = io:readln().trim();
        io:print("Description of fault: ");
        string desc = io:readln().trim();
        json payload = {orderId: id, status: "OPEN", description: desc, tasks: []};
        http:Response resp = check libraryClient->post(string `/assets/${tag}/workorders`, payload);
        check printResponse(resp, "Work order opened (asset marked UNDER_MAINTENANCE).");
    } else if choice == "2" {
        io:print("Order id: ");
        string id = io:readln().trim();
        io:print("New status (OPEN/IN_PROGRESS/CLOSED): ");
        string status = io:readln().trim();
        json payload = {status: status};
        http:Response resp = check libraryClient->put(string `/assets/${tag}/workorders/${id}`, payload);
        check printResponse(resp, "Work order updated.");
    } else if choice == "3" {
        io:print("Order id: ");
        string id = io:readln().trim();
        io:print("Task id: ");
        string taskId = io:readln().trim();
        io:print("Task description: ");
        string desc = io:readln().trim();
        json payload = {taskId: taskId, description: desc, status: "PENDING"};
        http:Response resp = check libraryClient->post(string `/assets/${tag}/workorders/${id}/tasks`, payload);
        check printResponse(resp, "Task added.");
    } else if choice == "4" {
        json response = check libraryClient->get(string `/assets/${tag}/workorders`);
        io:println(response.toJsonString());
    } else {
        io:println("Invalid choice.");
    }
}

// ---------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------
function printAssetList(json response) {
    if response is json[] {
        if response.length() == 0 {
            io:println("(no assets found)");
            return;
        }
        foreach json a in response {
            map<json> obj = <map<json>>a;
            io:println(string `• [${obj["assetTag"].toString()}] ${obj["name"].toString()}` +
                        string ` — ${obj["status"].toString()} @ ${obj["institution"].toString()}/${obj["site"].toString()}`);
        }
    } else {
        io:println(response.toJsonString());
    }
}

function printResponse(http:Response resp, string successMessage) returns error? {
    if resp.statusCode >= 200 && resp.statusCode < 300 {
        io:println("✓ " + successMessage);
    } else {
        json body = check resp.getJsonPayload();
        io:println(string `✗ Request failed (${resp.statusCode}): ${body.toJsonString()}`);
    }
}
