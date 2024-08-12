# GeoLocationDB

> [!CAUTION]
> This repository has been archived since the shutdown of the geolocation-db service. See [#1](https://github.com/thecoolwinter/GeoLocationDB/issues/1) for discussion. There are no plans to replace or fix this repository.

Uses the [https://geolocation-db.com](https://geolocation-db.com) api to get location information about an ip address. 

## Features

- Simple API
- Optional caching with Redis

## Setup

Install the package in your `Package.swift`
```swift
.package(url: "https://github.com/thecoolwinter/GeoLocationDB.git", from: "1.0.0")

.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "GeoLocationDB", package: "GeoLocationDB")
])
```
In your `configure.swift` file add a config with your api key and a bool for if you want to use Redis caching.

```swift
app.geoLocationDB.config = GeoLocationConfig(apiKey: "api-key",
                                            cache: true,
                                            cacheExpiration: 0) // Defaults to false
```

## Usage

You can use the `GeoLocationDB` object on any `Request` like so.

```swift
request.geoLocationDB.
```

`GeoLocationData` also conforms to Content, so you can encode it to JSON, or save it in a database as a `string` or `data`.
