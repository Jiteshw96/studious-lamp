//
//  HealthKitManager.swift
//  Atos-Healthkit
//
//  Created by Atos on 04/05/2020.
//  Copyright © 2020 Atos. All rights reserved.
//


import HealthKit
class HealthKitManager {
    
    class var sharedInstance: HealthKitManager {
        struct Singleton {
            static let instance = HealthKitManager()
        }
        
        return Singleton.instance
    }
    
    let healthKitStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
}
