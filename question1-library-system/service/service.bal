import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// ==========================================================================
// In-memory "database" — Maps keyed by the unique assetTag / institution name.
// (Per the brief: "Database: using Map or a table")
// ==========================================================================
map<Asset> assetStore = {};
map<Institution> institutionStore = {};

function nowDateString() returns string {
    time:Utc now = time:utcNow();
    string ts = time:utcToString(now);
    return ts.substring(0, 10); // "YYYY-MM-DD"
}

function errorBody(string message) returns ErrorDetail => {
    message: message,
    timestamp: time:utcToString(time:utcNow())
};

listener http:Listener libraryListener = new (8080);

service /library on libraryListener {

    // ---------------------------------------------------------------
    // A. Asset Management — CRUD
    // ---------------------------------------------------------------

    // Create a new asset
    resource function post assets(@http:Payload Asset newAsset)
            returns http:Created|http:Conflict|http:BadRequest {

        if newAsset.assetTag.trim().length() == 0 {
            return <http:BadRequest>{body: errorBody("assetTag is required")};
        }
        if assetStore.hasKey(newAsset.assetTag) {
            return <http:Conflict>{
                body: errorBody("Asset with tag '" + newAsset.assetTag + "' already exists")
            };
        }

        assetStore[newAsset.assetTag] = newAsset;

        // Auto-register the institution/site if this is the first time we see it.
        Institution? existing = institutionStore[newAsset.institution];
        if existing is () {
            institutionStore[newAsset.institution] = {name: newAsset.institution, sites: [newAsset.site]};
        } else if existing.sites.indexOf(newAsset.site) is () {
            existing.sites.push(newAsset.site);
            institutionStore[newAsset.institution] = existing;
        }

        log:printInfo("Created asset " + newAsset.assetTag);
        return <http:Created>{body: newAsset};
    }

    // B. View all assets — Global View
    resource function get assets() returns Asset[] {
        return assetStore.toArray();
    }

    // Look up a single asset
    resource function get assets/[string assetTag]() returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is Asset {
            return a;
        }
        return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
    }

    // Update an existing asset (full replace of the editable fields)
    resource function put assets/[string assetTag](@http:Payload Asset updated)
            returns Asset|http:NotFound|http:BadRequest {

        if !assetStore.hasKey(assetTag) {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        if updated.assetTag != assetTag {
            return <http:BadRequest>{body: errorBody("assetTag in body must match the path")};
        }
        assetStore[assetTag] = updated;
        return updated;
    }

    // Remove an asset
    resource function delete assets/[string assetTag]() returns http:Ok|http:NotFound {
        if !assetStore.hasKey(assetTag) {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        _ = assetStore.remove(assetTag);
        return <http:Ok>{body: {message: "Deleted " + assetTag}};
    }

    // ---------------------------------------------------------------
    // View assets by institution and site — Campus View
    // ---------------------------------------------------------------

    resource function get institutions/[string institution]/assets() returns Asset[] {
        return assetStore.toArray().filter(a => a.institution == institution);
    }

    resource function get institutions/[string institution]/sites/[string site]/assets() returns Asset[] {
        return assetStore.toArray().filter(a => a.institution == institution && a.site == site);
    }

    // ---------------------------------------------------------------
    // Manage institutions — add / remove / list
    // ---------------------------------------------------------------

    resource function post institutions(@http:Payload Institution inst)
            returns http:Created|http:Conflict {
        if institutionStore.hasKey(inst.name) {
            return <http:Conflict>{body: errorBody("Institution '" + inst.name + "' already exists")};
        }
        institutionStore[inst.name] = inst;
        return <http:Created>{body: inst};
    }

    resource function get institutions() returns Institution[] {
        return institutionStore.toArray();
    }

    resource function get institutions/[string institution]() returns Institution|http:NotFound {
        Institution? i = institutionStore[institution];
        if i is Institution {
            return i;
        }
        return <http:NotFound>{body: errorBody("Institution not found: " + institution)};
    }

    resource function delete institutions/[string institution]() returns http:Ok|http:NotFound|http:Conflict {
        if !institutionStore.hasKey(institution) {
            return <http:NotFound>{body: errorBody("Institution not found: " + institution)};
        }
        // Guard: don't silently orphan assets that still belong to this institution.
        boolean inUse = assetStore.toArray().some(a => a.institution == institution);
        if inUse {
            return <http:Conflict>{
                body: errorBody("Cannot remove '" + institution + "': assets are still registered under it")
            };
        }
        _ = institutionStore.remove(institution);
        return <http:Ok>{body: {message: "Institution removed: " + institution}};
    }

    // ---------------------------------------------------------------
    // Maintenance & Overdue checks
    // ---------------------------------------------------------------

    // Any asset with at least one schedule whose dueDate has already passed.
    resource function get assets/overdue() returns Asset[] {
        return assetStore.toArray().filter(a => a.schedules.some(s => s.dueDate < nowDateString()));
    }

    // Quick status + booking-schedule check for one asset
    resource function get assets/[string assetTag]/status()
            returns record {| string assetTag; Status status; Schedule[] schedules; |}|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is Asset {
            return {assetTag: a.assetTag, status: a.status, schedules: a.schedules};
        }
        return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
    }

    // ---------------------------------------------------------------
    // Loaning & booking a resource (used by the client's "Loan/Book" screen)
    // ---------------------------------------------------------------

    resource function post assets/[string assetTag]/loan(@http:Payload LoanRequest req)
            returns Asset|http:NotFound|http:Conflict {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        if a.status != "AVAILABLE" {
            return <http:Conflict>{body: errorBody("Asset '" + assetTag + "' is not AVAILABLE")};
        }
        a.status = "LOANED_OUT";
        Schedule sch = {
            scheduleId: uuid:createType1AsString().substring(0, 8),
            'type: "BOOKING",
            dueDate: req.dueDate,
            description: "Loaned/booked to " + req.borrower
        };
        a.schedules.push(sch);
        assetStore[assetTag] = a;
        return a;
    }

    resource function post assets/[string assetTag]/'return()
            returns Asset|http:NotFound|http:Conflict {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        if a.status != "LOANED_OUT" && a.status != "OCCUPIED" {
            return <http:Conflict>{body: errorBody("Asset '" + assetTag + "' was not on loan")};
        }
        a.status = "AVAILABLE";
        assetStore[assetTag] = a;
        return a;
    }

    // ---------------------------------------------------------------
    // Component & Schedule Management
    // ---------------------------------------------------------------

    resource function post assets/[string assetTag]/components(@http:Payload Component comp)
            returns Asset|http:NotFound|http:Conflict {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        if a.components.some(c => c.compId == comp.compId) {
            return <http:Conflict>{body: errorBody("Component id already exists on this asset")};
        }
        a.components.push(comp);
        assetStore[assetTag] = a;
        return a;
    }

    resource function delete assets/[string assetTag]/components/[string compId]()
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        a.components = a.components.filter(c => c.compId != compId);
        assetStore[assetTag] = a;
        return a;
    }

    resource function post assets/[string assetTag]/schedules(@http:Payload Schedule sch)
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        a.schedules.push(sch);
        assetStore[assetTag] = a;
        return a;
    }

    resource function get assets/[string assetTag]/schedules() returns Schedule[]|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is Asset {
            return a.schedules;
        }
        return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
    }

    resource function delete assets/[string assetTag]/schedules/[string scheduleId]()
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        a.schedules = a.schedules.filter(s => s.scheduleId != scheduleId);
        assetStore[assetTag] = a;
        return a;
    }

    // ---------------------------------------------------------------
    // Work Orders & Task Tracking
    // ---------------------------------------------------------------

    resource function post assets/[string assetTag]/workorders(@http:Payload WorkOrder wo)
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        a.workOrders.push(wo);
        // Opening a work order implies the asset needs attention.
        a.status = "UNDER_MAINTENANCE";
        assetStore[assetTag] = a;
        return a;
    }

    resource function get assets/[string assetTag]/workorders() returns WorkOrder[]|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is Asset {
            return a.workOrders;
        }
        return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
    }

    resource function put assets/[string assetTag]/workorders/[string orderId](@http:Payload WorkOrderStatusUpdate upd)
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        boolean found = false;
        foreach var wo in a.workOrders {
            if wo.orderId == orderId {
                wo.status = upd.status;
                found = true;
            }
        }
        if found && upd.status == "CLOSED" && !a.workOrders.some(w => w.status != "CLOSED") {
            a.status = "AVAILABLE";
        }
        assetStore[assetTag] = a;
        return a;
    }

    resource function delete assets/[string assetTag]/workorders/[string orderId]()
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        a.workOrders = a.workOrders.filter(w => w.orderId != orderId);
        assetStore[assetTag] = a;
        return a;
    }

    // Sub-tasks within a work order, e.g. "replace screen"
    resource function post assets/[string assetTag]/workorders/[string orderId]/tasks(@http:Payload Task t)
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        boolean found = false;
        foreach var wo in a.workOrders {
            if wo.orderId == orderId {
                wo.tasks.push(t);
                found = true;
            }
        }
        if !found {
            return <http:NotFound>{body: errorBody("Work order not found: " + orderId)};
        }
        assetStore[assetTag] = a;
        return a;
    }

    resource function put assets/[string assetTag]/workorders/[string orderId]/tasks/[string taskId](@http:Payload TaskStatusUpdate upd)
            returns Asset|http:NotFound {
        Asset? a = assetStore[assetTag];
        if a is () {
            return <http:NotFound>{body: errorBody("Asset not found: " + assetTag)};
        }
        foreach var wo in a.workOrders {
            if wo.orderId == orderId {
                foreach var t in wo.tasks {
                    if t.taskId == taskId {
                        t.status = upd.status;
                    }
                }
            }
        }
        assetStore[assetTag] = a;
        return a;
    }
}
