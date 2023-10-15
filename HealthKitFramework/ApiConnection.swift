//
//  ApiConnection.swift
//  HealthKitFramework
//
//  Created by Oskar Wong on 2023-10-13.
//

import Foundation
import Reachability

class ApiConnection {
    
    static let shared = ApiConnection()
    
    private let reachability = try? Reachability()
    
    private init(){
        
        startMonitoring()
    }
    
    func isNetworkAvailable() -> Bool {
        
        return reachability?.connection != .unavailable
    }
    
    private func startMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: .reachabilityChanged, object: reachability)
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to connect externally")
        }
    }
    
    @objc private func reachabilityChanged(notification: Notification) {
        if let reachbility = notification.object as? Reachability {
            if reachbility.connection != .unavailable {
                print("network is reachable")
            } else {
                print("network is  not reachable")
            }
        }
        
        
    }
    
}
