import ballerina/grpc;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;


map<PropertyResponse> propertyStore = {};

type CartEntry record {|
    string guestId;
    string propertyId;
    string checkIn;
    string checkOut;
|};
map<CartEntry> bookingCart = {};

type ConfirmedRange record {|
    string checkIn;
    string checkOut;
|};
map<ConfirmedRange[]> propertyBookings = {}; // property_id confirmed date ranges

// Helpers

function dayCount(string isoDate) returns int|error {
    time:Utc utc = check time:utcFromString(isoDate + "T00:00:00.00Z");
    return <int>(utc[0] / 86400);
}

function nightsBetween(string checkIn, string checkOut) returns int|error {
    int inDay = check dayCount(checkIn);
    int outDay = check dayCount(checkOut);
    return outDay - inDay;
}

function rangesOverlap(string aIn, string aOut, string bIn, string bOut) returns boolean {
    // Overlap unless one range ends before or when the other starts.
    return !(aOut <= bIn || bOut <= aIn);
}

function shortId(string prefix) returns string {
    return prefix + "-" + uuid:createType1AsString().substring(0, 8);
}

function emptyPropertyResponse(string propertyId, string message) returns PropertyResponse => {
    property_id: propertyId,
    host_id: "",
    name: "",
    location: "",
    property_type: "",
    price_per_night: 0.0,
    status: AVAILABLE,
    found: false,
    message: message
};

// Service

listener grpc:Listener rentalListener = new (9090);

@grpc:Descriptor {value: RENTAL_DESC}
service "RentalService" on rentalListener {

    // -------- add_property
    remote function addProperty(PropertyRequest req) returns PropertyIdResponse|error {
        if req.name.trim().length() == 0 || req.price_per_night <= 0.0 {
            return {property_id: "", message: "ERROR: name and a positive price_per_night are required"};
        }
        string id = shortId("PROP");
        PropertyResponse p = {
            property_id: id,
            host_id: req.host_id,
            name: req.name,
            location: req.location,
            property_type: req.property_type,
            price_per_night: req.price_per_night,
            status: req.status,
            found: true,
            message: "Created"
        };
        propertyStore[id] = p;
        log:printInfo("Property registered: " + id + " (" + req.name + ")");
        return {property_id: id, message: "Property registered successfully"};
    }

    // create_users (Client-side streaming)
    remote function createUsers(stream<UserProfile, grpc:Error?> clientStream) returns UserCreationSummary|error {
        int count = 0;
        error? e = clientStream.forEach(function(UserProfile u) {
            count += 1;
            log:printInfo("Registered user: " + u.name + " <" + u.email + "> role=" + u.role.toString());
        });
        if e is error {
            return e;
        }
        return {total_created: count, message: count.toString() + " user(s) registered successfully"};
    }

    //update_property 
    remote function updateProperty(UpdatePropertyRequest req) returns PropertyResponse|error {
        PropertyResponse? p = propertyStore[req.property_id];
        if p is () {
            return emptyPropertyResponse(req.property_id, "Property not found");
        }
        p.price_per_night = req.price_per_night;
        p.status = req.status;
        p.message = "Updated";
        propertyStore[req.property_id] = p;
        return p;
    }

    //remove_property 
    remote function removeProperty(RemovePropertyRequest req) returns PropertyList|error {
        PropertyResponse? existing = propertyStore[req.property_id];
        if existing is PropertyResponse && existing.host_id == req.host_id {
            _ = propertyStore.remove(req.property_id);
        }
        PropertyResponse[] remaining = propertyStore.toArray().filter(p => p.host_id == req.host_id);
        return {properties: remaining};
    }

    //list_available_properties (Server-side streaming)
    remote function listAvailableProperties(ListPropertiesRequest req) returns stream<PropertyResponse, error?>|error {
        PropertyResponse[] matches = propertyStore.toArray().filter(p =>
            p.status == AVAILABLE
            && (req.location_filter.trim().length() == 0 || p.location == req.location_filter)
            && (req.min_price <= 0.0 || p.price_per_night >= req.min_price)
            && (req.max_price <= 0.0 || p.price_per_night <= req.max_price)
        );
        return matches.toStream();
    }

    //search_property
    remote function searchProperty(SearchPropertyRequest req) returns PropertyResponse|error {
        PropertyResponse? p = propertyStore[req.property_id];
        if p is PropertyResponse {
            p.found = true;
            p.message = "Property found";
            return p;
        }
        return emptyPropertyResponse(req.property_id, "Not Available");
    }

    //book_property
    remote function bookProperty(BookPropertyRequest req) returns BookingCartResponse|error {
        PropertyResponse? p = propertyStore[req.property_id];
        if p is () {
            return {cart_id: "", success: false, message: "Property does not exist"};
        }
        int|error nights = nightsBetween(req.check_in, req.check_out);
        if nights is error || nights <= 0 {
            return {cart_id: "", success: false, message: "Invalid dates: check_out must be after check_in"};
        }
        if p.status != AVAILABLE {
            return {cart_id: "", success: false, message: "Property is not currently available"};
        }
        string cartId = shortId("CART");
        bookingCart[cartId] = {
            guestId: req.guest_id,
            propertyId: req.property_id,
            checkIn: req.check_in,
            checkOut: req.check_out
        };
        return {cart_id: cartId, success: true, message: "Added to booking cart — call confirm_booking to finalize"};
    }

    //confirm_booking
    remote function confirmBooking(ConfirmBookingRequest req) returns BookingConfirmation|error {
        CartEntry? entry = bookingCart[req.cart_id];
        if entry is () {
            return {success: false, booking_id: "", total_cost: 0.0, message: "Booking cart entry not found or already confirmed"};
        }
        if entry.guestId != req.guest_id {
            return {success: false, booking_id: "", total_cost: 0.0, message: "This cart entry does not belong to this guest"};
        }
        PropertyResponse? p = propertyStore[entry.propertyId];
        if p is () {
            _ = bookingCart.remove(req.cart_id);
            return {success: false, booking_id: "", total_cost: 0.0, message: "Property no longer exists"};
        }
        if p.status != AVAILABLE {
            return {success: false, booking_id: "", total_cost: 0.0, message: "Property is no longer available"};
        }

        // Verify no date overlap
        ConfirmedRange[] existingRanges = propertyBookings[entry.propertyId] ?: [];
        foreach ConfirmedRange r in existingRanges {
            if rangesOverlap(entry.checkIn, entry.checkOut, r.checkIn, r.checkOut) {
                return {success: false, booking_id: "", total_cost: 0.0, message: "Selected dates overlap an existing booking"};
            }
        }

        int|error nights = nightsBetween(entry.checkIn, entry.checkOut);
        if nights is error {
            return {success: false, booking_id: "", total_cost: 0.0, message: "Invalid dates"};
        }
        float totalCost = <float>nights * p.price_per_night;

        existingRanges.push({checkIn: entry.checkIn, checkOut: entry.checkOut});
        propertyBookings[entry.propertyId] = existingRanges;
        _ = bookingCart.remove(req.cart_id);

        string bookingId = shortId("BOOK");
        log:printInfo("Booking confirmed: " + bookingId + " for property " + entry.propertyId);
        return {success: true, booking_id: bookingId, total_cost: totalCost, message: "Booking confirmed"};
    }
}
