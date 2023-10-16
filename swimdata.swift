//
//  swimdata.swift
//  HealthKitFramework
//
//  Created by Oskar Wong on 2023-10-14.
//

import Foundation


struct SwimData: Codable {
    let lap: Int
    let StrokeCount: Double
    let lap_time: Double
    let swolf: Double
    
}

struct HRData: Codable {
    let min_HR: Double
    let max_HR: Double
    let total_HR: Double
    let total_CT: Int
}

struct SumofSimeData: Codable {
    let start_date: Double
    let total_time: Double
    let total_distance: Double
    let total_kcal: Double
    let length_lap: Int
    let pre_lap_record: [SwimData]
    let HR_data: HRData
}
