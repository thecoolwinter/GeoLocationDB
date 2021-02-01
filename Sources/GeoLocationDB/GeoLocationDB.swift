import Vapor
import Fluent
import Redis
import Foundation

public extension Request {
    var geoLocationDB: GeoLocationDB {
        .init(request: self)
    }
}

public struct GeoLocationConfig {
    var apiKey: String
    var cache: Bool = false
    /// Cache expiration in seconds, defaults to one day
    var cacheExpiration: Int = 86400
    
    public init(apiKey: String, cache: Bool = false, cacheExpiration: Int = 86400) {
        self.apiKey = apiKey
        self.cache = cache
        self.cacheExpiration = cacheExpiration
    }
}

public final class GeoLocationData: Content, RESPValueConvertible, Fields {
    
    /* Example Data
     {
     "country_code": "US"
     "country_name": "United States"
     "latitude": "46.7546"
     "longitude": "-92.5408"
     "IPv4": "50.81.224.152"
     }
     */
    @Field(key: "country_code")
    public var country_code: String?
    @Field(key: "country_name")
    public var country_name: String?
    @Field(key: "latitude")
    public var latitude: String?
    @Field(key: "longitude")
    public var longitude: String?
    @Field(key: "IPv4")
    public var IPv4: String?
    
    public init() { }
    
    public init(country_code: String?, country_name: String?, latitude: String?, longitude: String?, IPv4: String?) {
        self.country_code = country_code
        self.country_name = country_name
        self.latitude = latitude
        self.longitude = longitude
        self.IPv4 = IPv4
    }
    
    public init?(fromRESP value: RESPValue) {
        let decoder = JSONDecoder()
        guard let data = value.data else { return nil }
        guard let newSelf = try? decoder.decode(GeoLocationData.self, from: data) else { return nil }
        self.country_code = newSelf.country_code
        self.country_name = newSelf.country_name
        self.latitude = newSelf.latitude
        self.longitude = newSelf.longitude
        self.IPv4 = newSelf.IPv4
    }
    
    public func convertedToRESPValue() -> RESPValue {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = String(data: data, encoding: .utf8) ?? "{}"
        return RESPValue.bulkString(ByteBuffer(string: string))
    }
}

public struct GeoLocationDB {
    var request: Request
    private var application: Application {
        get {
            return request.application
        }
    }
    private var config: GeoLocationConfig {
        get {
            guard let config = request.application.geoLocationDB.config else {
                fatalError("You must add an apiKey to the GeoLocationDB config.")
            }
            return config
        }
    }
    
    private var baseUrl: String {
        get {
            "https://geolocation-db.com/json/\(config.apiKey)"
        }
    }
    
    private func urlFromIp(_ ip: String) -> URI {
        return URI(string: baseUrl + "/" + ip)
    }
    
    /// Gets a `GeoLocationData` object using the API
    /// - Parameter ip: The IP to look up
    /// - Returns: A `GeoLocationData` object for the IP Address
    public func locationDataFrom(ip: String) -> EventLoopFuture<GeoLocationData?> {
        if config.cache {
            return request.redis.get(RedisKey(rawValue: ip)!, asJSON: GeoLocationData.self).flatMap { (maybeData) -> EventLoopFuture<GeoLocationData?> in
                if let data = maybeData {
                    return request.eventLoop.makeSucceededFuture(data)
                } else {
                    return getDataFromServer(ip)
                }
            }
        }
        
        return getDataFromServer(ip)
    }
    
    private func getDataFromServer(_ ip: String) -> EventLoopFuture<GeoLocationData?> {
        return request.client.get(urlFromIp(ip)).flatMap { (res) -> EventLoopFuture<GeoLocationData?> in
            var response = res
            response.headers.contentType = .json // Fix the content-type
            if let geoData = try? response.content.decode(GeoLocationData.self) {
                if config.cache {
                    let key = RedisKey(ip)
                    return request.redis.set(key, toJSON: geoData)
                        .flatMap { return request.redis.expire(key, after: .seconds(Int64(config.cacheExpiration))) }
                        .transform(to: geoData)
                } else {
                    return request.eventLoop.makeSucceededFuture(geoData)
                }
            } else {
                return request.eventLoop.makeSucceededFuture(nil)
            }
        }
    }
}
