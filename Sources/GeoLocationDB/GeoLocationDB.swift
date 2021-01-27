import Vapor
import Redis
import Foundation

public extension Request {
    public var geoLocationDB: GeoLocationDB {
        .init(request: self)
    }
}

public struct GeoLocationConfig {
    public var apiKey: String
    public var cache: Bool = false
    /// Cache expiration in seconds, defaults to one day
    public var cacheExpiration: Int = 86400
}

public struct GeoLocationData: Content, RESPValueConvertible {
    /* Example Data
     {
     "country_code": "US"
     "country_name": "United States"
     "city": "Cloquet"
     "postal": "55720"
     "latitude": "46.7546"
     "longitude": "-92.5408"
     "IP": "50.81.224.152"
     "state": "Minnesota"
     }
     */
    public var country_code: String
    public var country_name: String
    public var city: String
    public var postal: String
    public var latitude: Double
    public var longitude: Double
    public var IP: String
    public var state: String
    
    public init(country_code: String, country_name: String, city: String, postal: String, latitude: Double, longitude: Double, IP: String, state: String) {
        self.country_code = country_code
        self.country_name = country_name
        self.city = city
        self.postal = postal
        self.latitude = latitude
        self.longitude = longitude
        self.IP = IP
        self.state = state
    }
    
    public init?(fromRESP value: RESPValue) {
        let decoder = JSONDecoder()
        guard let data = value.data else { return nil }
        guard let newSelf = try? decoder.decode(GeoLocationData.self, from: data) else { return nil }
        self = newSelf
    }
    
    public func convertedToRESPValue() -> RESPValue {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let string = String(data: data, encoding: .utf8) ?? "{}"
        return RESPValue.simpleString(ByteBuffer(string: string))
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
        return URI(string: baseUrl + ip)
    }
    
    /// Gets a `GeoLocationData` object using the API
    /// - Parameter ip: The IP to look up
    /// - Returns: A `GeoLocationData` object for the IP Address
    public func locationDataFrom(ip: String) -> EventLoopFuture<GeoLocationData> {
        if config.cache {
            return application.redis.get(RedisKey(rawValue: ip)!, as: GeoLocationData.self).flatMap { (maybeData) -> EventLoopFuture<GeoLocationData> in
                if let data = maybeData {
                    return request.eventLoop.makeSucceededFuture(data)
                } else {
                    return getDataFromServer(ip)
                }
            }
        }
        
        return getDataFromServer(ip)
    }
    
    private func getDataFromServer(_ ip: String) -> EventLoopFuture<GeoLocationData> {
        return request.client.get(urlFromIp(ip)).flatMap { (res) -> EventLoopFuture<GeoLocationData> in
            let geoData = try! res.content.decode(GeoLocationData.self)
            if config.cache {
                return request.application.redis.set(RedisKey(rawValue: ip)!, to: geoData, onCondition: .none, expiration: .seconds(config.cacheExpiration)).transform(to: geoData)
            } else {
                return request.eventLoop.makeSucceededFuture(geoData)
            }
        }
    }
}
