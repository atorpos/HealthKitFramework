//
//  HKmanager.swift
//  HealthTryOut
//
//  Created by Oskar Wong on 2023-10-11.
//

import Foundation
import HealthKit
import os.log

class HealthKitManager: ObservableObject {
    
    private var  healthStore = HKHealthStore()
    
    @Published var stepCount: [HKQuantitySample] = []
    private let os_log = OSLog(subsystem: "com.altawoz.healthtyout", category: "debugger")
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let healthStore = HKHealthStore()
        
        if HKHealthStore.isHealthDataAvailable() {
            let readType: Set<HKSampleType> = [HKSampleType.quantityType(forIdentifier: .stepCount)!,
                                               HKWorkoutType.workoutType(),
                                               HKQuantityType.quantityType(forIdentifier: .heartRate)!
            ]
            
            healthStore.requestAuthorization(toShare: nil, read: readType) { [self] (success, error) in
                if(success){
                    fetchSwimData()
                    self.get_item_to_file()
                } else {
                    
                }
                
            }
        }
    }
    
    func fetchStepCount() {
        
    }
    func fetchSwimData() {
        let workOutType = HKWorkoutType.workoutType()
//        let healthScore = HKHealthStore()
        let calendar = Calendar.current
        let endDate = Date()
//        let fs_queryGroup = DispatchGroup()
        
        let startDate = calendar.date(byAdding: .day, value: -3, to: endDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
            let query = HKSampleQuery(
                sampleType: workOutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil ) {(query, result, error) in
                    if let workouts = result as? [HKWorkout] {
                        
                        
                        for workout in workouts {
                            let wo_startDate = workout.startDate
                            let wo_endDate = workout.endDate
                            let activityType = workout.workoutActivityType.rawValue
                            let totalEnergyBurned = workout.totalEnergyBurned
                            print("Start date \(wo_startDate); End date \(wo_endDate) Activity Type: \(activityType); Total Energy Burn \(String(describing: totalEnergyBurned))")
//                                        let hearbut = workout.qu
//                                        os.os_log("The log %@", totalEnergyBurned ?? "nil")
//                                        if let associatedSamples = workout.workoutEvents {
//                                            for sample in associatedSamples {
////                                                print("Sample Type: \(sample)")
////                                                print("Sample Value: \(sample.value)")
//                                            }
//                                        }
                            self.fetchWOHR(startdate: wo_startDate, enddate: wo_endDate)
                            
                        }
                    } else {
                        
                    }
                }
            healthStore.execute(query)
        
//        let query = HKSampleQuery
    }
    
    func fetchWOHR(startdate: Date, enddate: Date ) {
        let heartScore = HKHealthStore()
        var totalHB: Double = 0.0
        var totalCount: Int = 0
        let queryGroup = DispatchGroup()
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: startdate, end: enddate, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil){ (query, results, error) in
            if let error = error {
                print ("query HR error \(error)")
                return
            }
            
            if let heartRateSamples = results as? [HKQuantitySample] {
                
                for sample in heartRateSamples {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
//                    let sampleDate = sample.startDate
//                    print("HR: \(heartRate) bpm, in time: \(sampleDate)")
                    totalCount += 1
                    totalHB += heartRate
                }
            }
            
            queryGroup.leave()
        }
        queryGroup.enter()
        heartScore.execute(query)
        queryGroup.wait()
        
        print("the start date \(startdate) and end date \(enddate) and the total count is \(totalCount), with totalHD \(totalHB)")
        
    }
    
    func get_item_to_file() {
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("active.txt")
            
            let text = "testing "
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
                print("file created and written")
            } catch {
                print("error")
            }
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("File is here")
            } else {
                print("file not here")
            }
        }
        
    }
    
}
