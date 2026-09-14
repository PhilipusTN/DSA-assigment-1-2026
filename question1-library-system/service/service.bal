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

    
}
