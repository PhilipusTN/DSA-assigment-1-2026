import ballerina/grpc;
import ballerina/protobuf;

public const string RENTAL_DESC = "0A0C72656E74616C2E70726F746F120672656E74616C22D7010A0F50726F70657274795265717565737412170A07686F73745F69641801200128095206686F7374496412120A046E616D6518022001280952046E616D65121A0A086C6F636174696F6E18032001280952086C6F636174696F6E12230A0D70726F70657274795F74797065180420012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180520012801520D70726963655065724E69676874122E0A0673746174757318062001280E32162E72656E74616C2E50726F70657274795374617475735206737461747573224F0A1250726F70657274794964526573706F6E7365121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412180A076D65737361676518022001280952076D65737361676522760A0B5573657250726F66696C6512170A07757365725F6964180120012809520675736572496412120A046E616D6518022001280952046E616D6512140A05656D61696C1803200128095205656D61696C12240A04726F6C6518042001280E32102E72656E74616C2E55736572526F6C655204726F6C6522540A13557365724372656174696F6E53756D6D61727912230A0D746F74616C5F63726561746564180120012805520C746F74616C4372656174656412180A076D65737361676518022001280952076D6573736167652290010A1555706461746550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412260A0F70726963655F7065725F6E69676874180220012801520D70726963655065724E69676874122E0A0673746174757318032001280E32162E72656E74616C2E50726F7065727479537461747573520673746174757322A9020A1050726F7065727479526573706F6E7365121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A07686F73745F69641802200128095206686F7374496412120A046E616D6518032001280952046E616D65121A0A086C6F636174696F6E18042001280952086C6F636174696F6E12230A0D70726F70657274795F74797065180520012809520C70726F70657274795479706512260A0F70726963655F7065725F6E69676874180620012801520D70726963655065724E69676874122E0A0673746174757318072001280E32162E72656E74616C2E50726F7065727479537461747573520673746174757312140A05666F756E641808200128085205666F756E6412180A076D65737361676518092001280952076D65737361676522510A1552656D6F766550726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F7065727479496412170A07686F73745F69641802200128095206686F7374496422480A0C50726F70657274794C69737412380A0A70726F7065727469657318012003280B32182E72656E74616C2E50726F7065727479526573706F6E7365520A70726F70657274696573227A0A154C69737450726F706572746965735265717565737412270A0F6C6F636174696F6E5F66696C746572180120012809520E6C6F636174696F6E46696C746572121B0A096D696E5F707269636518022001280152086D696E5072696365121B0A096D61785F707269636518032001280152086D6178507269636522380A1553656172636850726F706572747952657175657374121F0A0B70726F70657274795F6964180120012809520A70726F706572747949642289010A13426F6F6B50726F70657274795265717565737412190A0867756573745F6964180120012809520767756573744964121F0A0B70726F70657274795F6964180220012809520A70726F7065727479496412190A08636865636B5F696E1803200128095207636865636B496E121B0A09636865636B5F6F75741804200128095208636865636B4F757422620A13426F6F6B696E6743617274526573706F6E736512170A07636172745F6964180120012809520663617274496412180A077375636365737318022001280852077375636365737312180A076D65737361676518032001280952076D657373616765224B0A15436F6E6669726D426F6F6B696E675265717565737412170A07636172745F6964180120012809520663617274496412190A0867756573745F69641802200128095207677565737449642287010A13426F6F6B696E67436F6E6669726D6174696F6E12180A0773756363657373180120012808520773756363657373121D0A0A626F6F6B696E675F69641802200128095209626F6F6B696E674964121D0A0A746F74616C5F636F73741803200128015209746F74616C436F737412180A076D65737361676518042001280952076D6573736167652A410A0E50726F7065727479537461747573120D0A09415641494C41424C451000120F0A0B554E415641494C41424C451001120F0A0B4D41494E54454E414E434510022A1F0A0855736572526F6C6512080A04484F5354100012090A054755455354100132E1040A0D52656E74616C5365727669636512420A0B61646450726F706572747912172E72656E74616C2E50726F7065727479526571756573741A1A2E72656E74616C2E50726F70657274794964526573706F6E736512410A0B637265617465557365727312132E72656E74616C2E5573657250726F66696C651A1B2E72656E74616C2E557365724372656174696F6E53756D6D617279280112490A0E75706461746550726F7065727479121D2E72656E74616C2E55706461746550726F7065727479526571756573741A182E72656E74616C2E50726F7065727479526573706F6E736512450A0E72656D6F766550726F7065727479121D2E72656E74616C2E52656D6F766550726F7065727479526571756573741A142E72656E74616C2E50726F70657274794C69737412540A176C697374417661696C61626C6550726F70657274696573121D2E72656E74616C2E4C69737450726F70657274696573526571756573741A182E72656E74616C2E50726F7065727479526573706F6E7365300112490A0E73656172636850726F7065727479121D2E72656E74616C2E53656172636850726F7065727479526571756573741A182E72656E74616C2E50726F7065727479526573706F6E736512480A0C626F6F6B50726F7065727479121B2E72656E74616C2E426F6F6B50726F7065727479526571756573741A1B2E72656E74616C2E426F6F6B696E6743617274526573706F6E7365124C0A0E636F6E6669726D426F6F6B696E67121D2E72656E74616C2E436F6E6669726D426F6F6B696E67526571756573741A1B2E72656E74616C2E426F6F6B696E67436F6E6669726D6174696F6E620670726F746F33";

public isolated client class RentalServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, RENTAL_DESC);
    }

    isolated remote function addProperty(PropertyRequest|ContextPropertyRequest req) returns PropertyIdResponse|grpc:Error {
        map<string|string[]> headers = {};
        PropertyRequest message;
        if req is ContextPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/addProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyIdResponse>result;
    }

    isolated remote function addPropertyContext(PropertyRequest|ContextPropertyRequest req) returns ContextPropertyIdResponse|grpc:Error {
        map<string|string[]> headers = {};
        PropertyRequest message;
        if req is ContextPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/addProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyIdResponse>result, headers: respHeaders};
    }

    isolated remote function updateProperty(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns PropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/updateProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyResponse>result;
    }

    isolated remote function updatePropertyContext(UpdatePropertyRequest|ContextUpdatePropertyRequest req) returns ContextPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdatePropertyRequest message;
        if req is ContextUpdatePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/updateProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyResponse>result, headers: respHeaders};
    }

    isolated remote function removeProperty(RemovePropertyRequest|ContextRemovePropertyRequest req) returns PropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/removeProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyList>result;
    }

    isolated remote function removePropertyContext(RemovePropertyRequest|ContextRemovePropertyRequest req) returns ContextPropertyList|grpc:Error {
        map<string|string[]> headers = {};
        RemovePropertyRequest message;
        if req is ContextRemovePropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/removeProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyList>result, headers: respHeaders};
    }

    isolated remote function searchProperty(SearchPropertyRequest|ContextSearchPropertyRequest req) returns PropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/searchProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <PropertyResponse>result;
    }

    isolated remote function searchPropertyContext(SearchPropertyRequest|ContextSearchPropertyRequest req) returns ContextPropertyResponse|grpc:Error {
        map<string|string[]> headers = {};
        SearchPropertyRequest message;
        if req is ContextSearchPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/searchProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <PropertyResponse>result, headers: respHeaders};
    }

    isolated remote function bookProperty(BookPropertyRequest|ContextBookPropertyRequest req) returns BookingCartResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/bookProperty", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookingCartResponse>result;
    }

    isolated remote function bookPropertyContext(BookPropertyRequest|ContextBookPropertyRequest req) returns ContextBookingCartResponse|grpc:Error {
        map<string|string[]> headers = {};
        BookPropertyRequest message;
        if req is ContextBookPropertyRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/bookProperty", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookingCartResponse>result, headers: respHeaders};
    }

    isolated remote function confirmBooking(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns BookingConfirmation|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <BookingConfirmation>result;
    }

    isolated remote function confirmBookingContext(ConfirmBookingRequest|ContextConfirmBookingRequest req) returns ContextBookingConfirmation|grpc:Error {
        map<string|string[]> headers = {};
        ConfirmBookingRequest message;
        if req is ContextConfirmBookingRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("rental.RentalService/confirmBooking", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <BookingConfirmation>result, headers: respHeaders};
    }

    isolated remote function createUsers() returns CreateUsersStreamingClient|grpc:Error {
        grpc:StreamingClient sClient = check self.grpcClient->executeClientStreaming("rental.RentalService/createUsers");
        return new CreateUsersStreamingClient(sClient);
    }

    isolated remote function listAvailableProperties(ListPropertiesRequest|ContextListPropertiesRequest req) returns stream<PropertyResponse, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListPropertiesRequest message;
        if req is ContextListPropertiesRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/listAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        PropertyResponseStream outputStream = new PropertyResponseStream(result);
        return new stream<PropertyResponse, grpc:Error?>(outputStream);
    }

    isolated remote function listAvailablePropertiesContext(ListPropertiesRequest|ContextListPropertiesRequest req) returns ContextPropertyResponseStream|grpc:Error {
        map<string|string[]> headers = {};
        ListPropertiesRequest message;
        if req is ContextListPropertiesRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("rental.RentalService/listAvailableProperties", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        PropertyResponseStream outputStream = new PropertyResponseStream(result);
        return {content: new stream<PropertyResponse, grpc:Error?>(outputStream), headers: respHeaders};
    }
}

public isolated client class CreateUsersStreamingClient {
    private final grpc:StreamingClient sClient;

    isolated function init(grpc:StreamingClient sClient) {
        self.sClient = sClient;
    }

    isolated remote function sendUserProfile(UserProfile message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function sendContextUserProfile(ContextUserProfile message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function receiveUserCreationSummary() returns UserCreationSummary|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, _] = response;
            return <UserCreationSummary>payload;
        }
    }

    isolated remote function receiveContextUserCreationSummary() returns ContextUserCreationSummary|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, headers] = response;
            return {content: <UserCreationSummary>payload, headers: headers};
        }
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.sClient->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.sClient->complete();
    }
}

public class PropertyResponseStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|PropertyResponse value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|PropertyResponse value;|} nextRecord = {value: <PropertyResponse>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public type ContextUserProfileStream record {|
    stream<UserProfile, error?> content;
    map<string|string[]> headers;
|};

public type ContextPropertyResponseStream record {|
    stream<PropertyResponse, error?> content;
    map<string|string[]> headers;
|};

public type ContextBookPropertyRequest record {|
    BookPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextListPropertiesRequest record {|
    ListPropertiesRequest content;
    map<string|string[]> headers;
|};

public type ContextUserProfile record {|
    UserProfile content;
    map<string|string[]> headers;
|};

public type ContextUpdatePropertyRequest record {|
    UpdatePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextBookingCartResponse record {|
    BookingCartResponse content;
    map<string|string[]> headers;
|};

public type ContextConfirmBookingRequest record {|
    ConfirmBookingRequest content;
    map<string|string[]> headers;
|};

public type ContextUserCreationSummary record {|
    UserCreationSummary content;
    map<string|string[]> headers;
|};

public type ContextPropertyResponse record {|
    PropertyResponse content;
    map<string|string[]> headers;
|};

public type ContextPropertyList record {|
    PropertyList content;
    map<string|string[]> headers;
|};

public type ContextRemovePropertyRequest record {|
    RemovePropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextBookingConfirmation record {|
    BookingConfirmation content;
    map<string|string[]> headers;
|};

public type ContextPropertyIdResponse record {|
    PropertyIdResponse content;
    map<string|string[]> headers;
|};

public type ContextSearchPropertyRequest record {|
    SearchPropertyRequest content;
    map<string|string[]> headers;
|};

public type ContextPropertyRequest record {|
    PropertyRequest content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookPropertyRequest record {|
    string guest_id = "";
    string property_id = "";
    string check_in = "";
    string check_out = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ListPropertiesRequest record {|
    string location_filter = "";
    float min_price = 0.0;
    float max_price = 0.0;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UserProfile record {|
    string user_id = "";
    string name = "";
    string email = "";
    UserRole role = HOST;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UpdatePropertyRequest record {|
    string property_id = "";
    float price_per_night = 0.0;
    PropertyStatus status = AVAILABLE;
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookingCartResponse record {|
    string cart_id = "";
    boolean success = false;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type ConfirmBookingRequest record {|
    string cart_id = "";
    string guest_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type UserCreationSummary record {|
    int total_created = 0;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type PropertyResponse record {|
    string property_id = "";
    string host_id = "";
    string name = "";
    string location = "";
    string property_type = "";
    float price_per_night = 0.0;
    PropertyStatus status = AVAILABLE;
    boolean found = false;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type PropertyList record {|
    PropertyResponse[] properties = [];
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type RemovePropertyRequest record {|
    string property_id = "";
    string host_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type BookingConfirmation record {|
    boolean success = false;
    string booking_id = "";
    float total_cost = 0.0;
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type PropertyIdResponse record {|
    string property_id = "";
    string message = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type SearchPropertyRequest record {|
    string property_id = "";
|};

@protobuf:Descriptor {value: RENTAL_DESC}
public type PropertyRequest record {|
    string host_id = "";
    string name = "";
    string location = "";
    string property_type = "";
    float price_per_night = 0.0;
    PropertyStatus status = AVAILABLE;
|};

public enum PropertyStatus {
    AVAILABLE, UNAVAILABLE, MAINTENANCE
}

public enum UserRole {
    HOST, GUEST
}
