import ballerina/grpc;
import ballerina/io;

final RentalServiceClient rentalClient = check new ("http://localhost:9090");

int userCounter = 0;

public function main() returns error? {
    boolean running = true;
    while running {
        io:println("\n================ Rental Accommodation gRPC Client ================");
        io:println(" 1. Add property");
        io:println(" 2. Register users");
        io:println(" 3. Update property");
        io:println(" 4. Remove property");
        io:println(" 5. List available properties");
        io:println(" 6. Search property");
        io:println(" 7. Book property");
        io:println(" 8. Confirm booking");
        io:println(" 0. Exit");
        io:print("Select option: ");
        string choice = io:readln().trim();

        error? result = ();
        if choice == "1" {
            result = addProperty();
        } else if choice == "2" {
            result = registerUsers();
        } else if choice == "3" {
            result = updateProperty();
        } else if choice == "4" {
            result = removeProperty();
        } else if choice == "5" {
            result = listAvailable();
        } else if choice == "6" {
            result = searchProperty();
        } else if choice == "7" {
            result = bookProperty();
        } else if choice == "8" {
            result = confirmBooking();
        } else if choice == "0" {
            running = false;
            continue;
        } else {
            io:println("Invalid option, try again.");
            continue;
        }

        if result is error {
            io:println("RPC error: " + result.message());
        }
    }
    io:println("Goodbye!");
}

function readStatus() returns PropertyStatus {
    io:print("Status (0=AVAILABLE, 1=UNAVAILABLE, 2=MAINTENANCE): ");
    string s = io:readln().trim();
    if s == "1" {
        return UNAVAILABLE;
    } else if s == "2" {
        return MAINTENANCE;
    }
    return AVAILABLE;
}

//1. add property
function addProperty() returns error? {
    io:print("Host id: ");
    string hostId = io:readln().trim();
    io:print("Property name: ");
    string name = io:readln().trim();
    io:print("Location: ");
    string location = io:readln().trim();
    io:print("Property type (apartment/house/room): ");
    string ptype = io:readln().trim();
    io:print("Price per night: ");
    float price = check float:fromString(io:readln().trim());
    PropertyStatus status = readStatus();

    PropertyIdResponse res = check rentalClient->addProperty({
        host_id: hostId,
        name: name,
        location: location,
        property_type: ptype,
        price_per_night: price,
        status: status
    });
    io:println("✓ " + res.message + " -> property_id = " + res.property_id);
}

// 2. create users
function registerUsers() returns error? {
    io:println("Enter user details. Leave name blank to finish and send the batch.");
    CreateUsersStreamingClient createUsersStreamingClient = check rentalClient->createUsers();

    while true {
        io:print("Name (blank to stop): ");
        string name = io:readln().trim();
        if name == "" {
            break;
        }
        io:print("Email: ");
        string email = io:readln().trim();
        io:print("Role (0=HOST, 1=GUEST): ");
        string roleStr = io:readln().trim();
        UserRole role = roleStr == "0" ? HOST : GUEST;

        userCounter += 1;
        UserProfile profile = {
            user_id: "USR-" + userCounter.toString(),
            name: name,
            email: email,
            role: role
        };
        check createUsersStreamingClient->sendUserProfile(profile);
    }

    check createUsersStreamingClient->complete();
     UserCreationSummary? summary = check createUsersStreamingClient->receiveUserCreationSummary();
    if summary is UserCreationSummary {
        io:println("✓ " + summary.message);
    } else {
        io:println("✗ No confirmation received from server.");
    }
}
// 3. update property
function updateProperty() returns error? {
    io:print("Property id: ");
    string id = io:readln().trim();
    io:print("New price per night: ");
    float price = check float:fromString(io:readln().trim());
    PropertyStatus status = readStatus();

    PropertyResponse res = check rentalClient->updateProperty({
        property_id: id,
        price_per_night: price,
        status: status
    });
    if res.found {
        io:println("✓ Updated: " + res.name + " now $" + res.price_per_night.toString() + "/night, status=" + res.status.toString());
    } else {
        io:println("✗ " + res.message);
    }
}

//4.remove property
function removeProperty() returns error? {
    io:print("Property id: ");
    string id = io:readln().trim();
    io:print("Host id (must match owner): ");
    string hostId = io:readln().trim();

    PropertyList remaining = check rentalClient->removeProperty({property_id: id, host_id: hostId});
    io:println("Remaining properties for this host:");
    foreach PropertyResponse p in remaining.properties {
        io:println("  • [" + p.property_id + "] " + p.name + " — $" + p.price_per_night.toString() + "/night");
    }
    if remaining.properties.length() == 0 {
        io:println("  (none)");
    }
}

// 5. list available properties (server streaming)
function readOptionalFloat(string prompt) returns float|error {
    io:print(prompt);
    string s = io:readln().trim();
    if s == "" {
        return 0.0;
    }
    return float:fromString(s);
}

function listAvailable() returns error? {
    io:print("Filter by location (blank for none): ");
    string loc = io:readln().trim();
    float minP = check readOptionalFloat("Min price (blank for none): ");
    float maxP = check readOptionalFloat("Max price (blank for none): ");

    stream<PropertyResponse, grpc:Error?> results = check rentalClient->listAvailableProperties({
        location_filter: loc,
        min_price: minP,
        max_price: maxP
    });

    io:println("=== Available properties ==");
    int count = 0;
    error? e = results.forEach(function(PropertyResponse p) {
        count += 1;
        io:println("  • [" + p.property_id + "] " + p.name + " @ " + p.location +
                " — $" + p.price_per_night.toString() + "/night");
    });
    if e is error {
        return e;
    }
    if count == 0 {
        io:println("  (no properties matched)");
    }
}

// 6. search property
function searchProperty() returns error? {
    io:print("Property id: ");
    string id = io:readln().trim();
    PropertyResponse res = check rentalClient->searchProperty({property_id: id});
    if res.found {
        io:println("✓ " + res.name + " @ " + res.location + " — $" + res.price_per_night.toString() +
                "/night, status=" + res.status.toString());
    } else {
        io:println("✗ " + res.message);
    }
}

// 7. book property
function bookProperty() returns error? {
    io:print("Guest id: ");
    string guestId = io:readln().trim();
    io:print("Property id: ");
    string propId = io:readln().trim();
    io:print("Check-in (YYYY-MM-DD): ");
    string checkIn = io:readln().trim();
    io:print("Check-out (YYYY-MM-DD): ");
    string checkOut = io:readln().trim();

    BookingCartResponse res = check rentalClient->bookProperty({
        guest_id: guestId,
        property_id: propId,
        check_in: checkIn,
        check_out: checkOut
    });
    if res.success {
        io:println("✓ " + res.message + " -> cart_id = " + res.cart_id);
    } else {
        io:println("✗ " + res.message);
    }
}

// 8. confirm booking
function confirmBooking() returns error? {
    io:print("Cart id: ");
    string cartId = io:readln().trim();
    io:print("Guest id: ");
    string guestId = io:readln().trim();

    BookingConfirmation res = check rentalClient->confirmBooking({cart_id: cartId, guest_id: guestId});
    if res.success {
        io:println("✓ " + res.message + " -> booking_id = " + res.booking_id +
                ", total_cost = $" + res.total_cost.toString());
    } else {
        io:println("✗ " + res.message);
    }
}
