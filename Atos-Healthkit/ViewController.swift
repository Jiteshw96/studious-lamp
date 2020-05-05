//
//  ViewController.swift
//  Atos-Healthkit
//
//  Created by Atos on 04/05/2020.
//  Copyright © 2020 Atos. All rights reserved.
//

import UIKit
import HealthKit

let healthKitStore:HKHealthStore = HKHealthStore()

class ViewController: UIViewController {
      
    @IBOutlet weak var labelAge: UILabel!
    @IBOutlet weak var labelBloodtype: UILabel!
    @IBOutlet weak var stepCount: UILabel!
    @IBOutlet weak var weekStepCount: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
  
    @IBAction func authorizeHealthKitBtn(_ sender: Any) {
        self.authorizeHealthKitApp()
    }
    
    @IBAction func getDetails(_ sender: Any) {
        let (age , bloodType) = self.readProfile()
        
        self.labelAge.text = "\(String(describing: age!))"
        self.labelBloodtype.text = getBloodGroup(bloodType: bloodType?.bloodType)
        self.getTodaysSteps { (steps) in
            let steps = Int(steps)
             DispatchQueue.main.async {
            self.stepCount.text = "\(String(describing: steps))"
            }
        }
        
        self.getTotalSteps(forPast: 3) { (steps) in
            let steps = Int(steps)
            DispatchQueue.main.async {
            self.weekStepCount.text = "\(String(describing: steps))"
            }
        }
    }
    
    //Read User Profile 
    func readProfile()-> (age:Int? , bloodType:HKBloodTypeObject?){
        var age:Int?
        var bloodType:HKBloodTypeObject?
        
        //Read Age From HealthKit App
        do{
            let birthday = try healthKitStore.dateOfBirthComponents()
            let calendar = Calendar.current
            let currentYear =  calendar.component(.year, from: Date())
            age = currentYear - birthday.year!
            
        }catch { }
        
        //Read BloodType From HealthKit App
        
        do{
            bloodType = try healthKitStore.bloodType()
        }catch{}
        
        return(age ,bloodType)
        
    }
    
    //Request For Authorization
    func authorizeHealthKitApp(){
        let healthKitTypesToRead :  Set<HKObjectType>  = [
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
          //  HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
        ]
        
         let healthKitTypesToWrite : Set<HKSampleType> = []
    
       /* let healthKitTypes: Set = [
            // access step count
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        ]*/
       
        if !HKHealthStore.isHealthDataAvailable(){
            print("Some Error Occured")
            return
        }
 
        healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead)
        { (success, error) ->Void in
            print("Read Write Authorization Success")
            print(error ?? "Detail Not found ")
        }
    }
    
    func getBloodGroup(bloodType:HKBloodType?)-> String{
           
           var bloodTypeText = "";
        
           if(bloodType != nil){
            
               switch (bloodType!) {
               case .aPositive:
                   bloodTypeText = "A+"
               case .aNegative:
                   bloodTypeText = "A-"
               case .bPositive:
                   bloodTypeText = "B+"
               case .bNegative:
                   bloodTypeText = "B-"
               case .abPositive:
                   bloodTypeText = "AB+"
               case .abNegative:
                   bloodTypeText = "AB-"
               case .oPositive:
                   bloodTypeText = "O+"
               case .oNegative:
                   bloodTypeText = "O-"
               default:
                 bloodTypeText =  "Unknown"
                   break
               }
               
           }
           return bloodTypeText
       }
    
   func getTodaysSteps(completion: @escaping (Double) -> Void) {
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
       let startOfDay = Calendar.current.startOfDay(for: now)
       let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
       // let exactlySevenDaysAgo = Calendar.current.date(byAdding: DateComponents(day: -7), to: now)!
        //   let startOfSevenDaysAgo = Calendar.current.startOfDay(for: exactlySevenDaysAgo)
        //   let predicate = HKQuery.predicateForSamples(withStart: startOfSevenDaysAgo, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount:Double?
            guard let result = result else {
                print("Failed to fetch steps rate")
                completion(resultCount!)
                return
            }
            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.count())
            }
            
            DispatchQueue.main.async {
                completion(resultCount!)
            }
        }
        healthKitStore.execute(query)
    }
    
    
    func getTotalSteps(forPast days: Int, completion: @escaping (Double) -> Void) {
        // Getting quantityType as stepCount
        guard let stepsQuantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Unable to create a step count type")
            return
        }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: DateComponents(day: -days), to: now)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        healthKitStore.execute(query)
    }
    
  /* func getMostRecentStep(for sampleType: HKQuantityType, completion: @escaping (_ stepRetrieved: Int, _ stepAll : [[String : String]]) -> Void) {
           
           // Use HKQuery to load the most recent samples.
           let mostRecentPredicate =  HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
           
           var interval = DateComponents()
           interval.day = 3
           
           let stepQuery = HKStatisticsCollectionQuery(quantityType: sampleType , quantitySamplePredicate: mostRecentPredicate, options: .cumulativeSum, anchorDate: Date.distantPast, intervalComponents: interval)
           
           stepQuery.initialResultsHandler = { query, results, error in
               
               if error != nil {
                   //  Something went Wrong
                   return
               }
               if let myResults = results {
                   
                   var stepsData : [[String:String]] = [[:]]
                   var steps : Int = Int()
                   stepsData.removeAll()
                   
                   myResults.enumerateStatistics(from: Date.distantPast, to: Date()) {
                       
                       statistics, stop in
                       
                       //Take Local Variable
                       
                       if let quantity = statistics.sumQuantity() {
                           
                           let dateFormatter = DateFormatter()
                           dateFormatter.dateFormat = "MMM d, yyyy"
                           dateFormatter.locale =  NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
                           dateFormatter.timeZone = NSTimeZone.local
                           
                           var tempDic : [String : String]?
                           let endDate : Date = statistics.endDate
                           
                           steps = Int(quantity.doubleValue(for: HKUnit.count()))
                           
                           print("DataStore Steps = \(steps)")
                           
                           tempDic = [
                               "enddate" : "\(dateFormatter.string(from: endDate))",
                               "steps"   : "\(steps)"
                           ]
                           stepsData.append(tempDic!)
                       }
                   }
                   completion(steps, stepsData.reversed())
               }
           }
           HKHealthStore().execute(stepQuery)
       }*/
}

