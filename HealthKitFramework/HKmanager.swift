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
    @Published var HK_auth:Bool = false
    let userdefault = UserDefaults.standard
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let healthStore = HKHealthStore()
        let workoutType = HKWorkoutType.workoutType()
        if HKHealthStore.isHealthDataAvailable() {
            let readType: Set<HKSampleType> = [HKSampleType.quantityType(forIdentifier: .stepCount)!,
                                               HKWorkoutType.workoutType(),
                                               HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                                               HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!,
                                               HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!,
                                               workoutType
            ]
            healthStore.requestAuthorization(toShare: nil, read: readType) { [self] (success, error) in
                if(success){
                    userdefault.set(true, forKey: "HKGrant")
                } else {
                    userdefault.set(false, forKey: "HKGrant")
                }
                
            }
        } else {
            userdefault.set(false, forKey: "HKGrant")
        }
    }
    
    func fetchStepCount() {
        
    }
    func fetchSwimData() {
        let workOutType = HKWorkoutType.workoutType()
        let gen_healthScore = HKHealthStore()
        let calendar = Calendar.current
        let endDate = Date()
        let fs_queryGroup = DispatchGroup()
        let backgroundQueue = DispatchQueue(label: "com.altawoz.HealthKitFramework", qos: .background)
        var sum_lapArray:[SumofSimeData] = []
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
            let query = HKSampleQuery(
                sampleType: workOutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil ) {(query, result, error) in
                    if let workouts = result as? [HKWorkout] {
                        
                        
                        for workout in workouts {
                            let onelap_array = self.fetchSTIME(singleWodata: workout)
                            let wo_startDate = workout.startDate
                            let wo_endDate = workout.endDate
                            let activityType = workout.workoutActivityType.rawValue
//                            let SWOP = workout.workoutActivities.
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
                            let one_activ_record = SumofSimeData(start_date: wo_startDate, total_time: wo_endDate.timeIntervalSince(startDate!), pre_lap_record: onelap_array)
                            sum_lapArray.append(one_activ_record)
                        }
                    } else {
                        
                    }
                    fs_queryGroup.leave()
                }
        fs_queryGroup.enter()
        backgroundQueue.async {
            gen_healthScore.execute(query)
            fs_queryGroup.wait()
            self.transform_to_json(recordArray: sum_lapArray)
        }
        
        
        
//        let query = HKSampleQuery
    }
    
    func fetchSTIME(singleWodata: HKWorkout) -> [SwimData] {
        let SWLScore = HKHealthStore()
        let queryGroup = DispatchGroup()
        
        let s_quantitySet: [HKQuantityType] = [HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!, HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!]
        var laptime = 0.0
        var laptimeinms = 0.0
        var stoke_count = 0.0
        var one_lapArray: [SwimData] = []
        if(singleWodata.workoutActivityType.rawValue != 46){
            print("it is not swim")
            return []
        }
        print("it is swim")
        for s_quantityType in s_quantitySet {
            let assoicatedSamplesQuery = HKSampleQuery(
                sampleType: s_quantityType, predicate: HKQuery.predicateForObjects(from: singleWodata), limit: 0, sortDescriptors: nil) { (sq_query, sq_sample, sq_error) in
                    if let swimLapSampe = sq_sample as? [HKQuantitySample] {
                        print("can get laps")
                        var lapcount = 0;
                        for sample in swimLapSampe {
                            if(s_quantityType.identifier == "HKQuantityTypeIdentifierSwimmingStrokeCount") {
                                stoke_count = sample.quantity.doubleValue(for: HKUnit.count())
                                print("\(s_quantityType.identifier): \(stoke_count)")
                                lapcount = lapcount + 1
                                laptimeinms = self.each_laptime(lapcount: lapcount, starttime: sample.startDate, endTime: sample.endDate)
                                laptime = laptime + laptimeinms
                                let swolf = self.swolf_cal(lapcount: lapcount, lap_pace: laptimeinms, lap_stroke: stoke_count)
                                let lap_record = SwimData(lap: lapcount, StrokeCount: stoke_count, lap_time: laptimeinms, swolf: swolf)
                                one_lapArray.append(lap_record)
                            } else {
                                continue
                            }
                        }
                    } else {
                        print("no laps \(String(describing: sq_error))")
                    }
                    queryGroup.leave()
                }
            queryGroup.enter()
            SWLScore.execute(assoicatedSamplesQuery)
            queryGroup.wait()
        }
        
        print("Total time = \(laptime)")
        return one_lapArray
    }
    
    func each_laptime(lapcount: Int, starttime: Date, endTime: Date) -> Double {
        let timeDiff = endTime.timeIntervalSince(starttime)
        print("\(lapcount) lap time \(timeDiff)")
        return timeDiff
    }
    
    func swolf_cal(lapcount: Int, lap_pace: Double, lap_stroke: Double)-> Double {
        let swolf = lap_pace + lap_stroke
        return swolf
        
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
    
    func transform_to_json(recordArray: [SumofSimeData]){
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(recordArray)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } catch {
            print("Error encoding to JSON: \(error)")
        }
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
