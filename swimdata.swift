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

struct SumofSimeData: Codable {
    let start_date: Date
    let total_time: Double
    let pre_lap_record: [SwimData]
}
