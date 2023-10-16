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
    
    func submitActivity(sm_data: Data) {
        
        let url = URL(string: "https://s.awoz.co/receive_json.php")!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        request.httpBody = sm_data
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request){ (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data, let respnose = response as? HTTPURLResponse {
                print("Response status code: \(String(describing: response))")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("REspnose Data: \(responseString)")
                }
            }
            
        }
        task.resume()
    }
    
}
