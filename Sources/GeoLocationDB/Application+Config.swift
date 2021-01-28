//
//  Application+Config.swift
//  
//
//  Created by Khan Winter on 1/27/21.
//

import Vapor

extension Application {
    public struct GeoLocationDB {
        let app: Application
        
        private final class Storage {
            var config: GeoLocationConfig?
            
            init() {}
        }
        
        private struct Key: StorageKey {
            typealias Value = Storage
        }
        
        private var storage: Storage {
            if app.storage[Key.self] == nil {
                app.storage[Key.self] = .init()
            }
            
            return app.storage[Key.self]!
        }
        
        public var config: GeoLocationConfig? {
            get { storage.config }
            nonmutating set { storage.config = newValue }
        }
    }
    
    public var geoLocationDB: GeoLocationDB {
        .init(app: self)
    }
}
