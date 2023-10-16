//
//  HealthKitFrameworkApp.swift
//  HealthKitFramework
//
//  Created by Oskar Wong on 2023-10-13.
//

import SwiftUI
import SwiftData

@main
struct HealthKitFrameworkApp: App {
    
    let networkManage = ApiConnection.shared
    let hkManager = HealthKitManager()
    @State private var HKauthor:Bool = false;
    let userDefault = UserDefaults.standard
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if networkManage.isNetworkAvailable(){
                        print("network connected")
                    } else {
                        print("network not connected")
                    }
                }
                .onAppear(perform: {
                    hkManager.requestAuthorization()
                    if(userDefault.bool(forKey: "HKGrant")){
                        print("granted")
                        hkManager.fetchSwimData()
                    } else {
                        print("not granted")
                    }
                })
        }
        .modelContainer(sharedModelContainer)
    }
}
