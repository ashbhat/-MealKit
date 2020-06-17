//
//  CoreDataSingleton.swift
//  MealKit
//
//  Created by Developer on 5/14/20.
//  Copyright © 2020 Developer. All rights reserved.
//

import UIKit
import CoreData

struct MealData {
    var name: String
    var note: String
    var type: MealType
    var created: Date
    var identifier: String
    var ingredients: [String]
}

class CoreDataSingleton: NSObject {
    static let shared = CoreDataSingleton()
    
    func saveMeal(name: String, note: String, type: MealType) -> MealData {
        let meal = Meal(context: CoreDataManager.sharedManager.context)
        meal.name = name
        meal.note = note
        meal.type = type.name
        meal.created = Date()
        meal.identifier = UUID().uuidString
        meal.ingredients = []
        CoreDataManager.sharedManager.save()
        return MealData(name: name, note: note, type: type, created: meal.created!, identifier: meal.identifier!, ingredients: [])
    }

    
    func getMealsFor(type: MealType, archived: Bool) -> [MealData] {
        
        let recent = NSSortDescriptor(key: "created", ascending: false)
        let ofType = NSPredicate(format: "type == %@", type.name)
        let notArchived = NSPredicate(format: "archived == %@", NSNumber(value: archived))
        
        
        let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [notArchived, ofType])
        
        let meals = retrieveAll(forEntityName: "Meal", sortedBy: [recent], withFilter: compoundPredicate) as? [Meal]
        var mealsData : [MealData] = []
        
        if meals == nil {
            return []
        }
        
        
        for meal in meals! {
            mealsData.append(mealToData(meal: meal))
        }
        
        return mealsData
    }

    
    func archive(_ archive : Bool, identifier: String) {
        let withIdentifier = NSPredicate(format: "identifier == %@", identifier)
        let meal = retrieve(forEntityName: "Meal", withFilter: withIdentifier) as! Meal
        meal.archived = archive
        CoreDataManager.sharedManager.save()
    }
    
    func saveIngredients(_ ingredients: [String], for identifier: String) {
        let withIdentifier = NSPredicate(format: "identifier == %@", identifier)
        let meal = retrieve(forEntityName: "Meal", withFilter: withIdentifier) as! Meal
        meal.ingredients = ingredients
        CoreDataManager.sharedManager.save()
    }
    
    func getMeal(identifier: String) -> MealData? {
        let withIdentifier = NSPredicate(format: "identifier == %@", identifier)
        let meal = retrieve(forEntityName: "Meal", withFilter: withIdentifier) as? Meal
        if meal == nil {return nil}
        return mealToData(meal: meal!)
    }
    
    func mealToData(meal: Meal) -> MealData {
        return MealData(name: meal.name!, note: meal.note!, type: MealType(rawValue: meal.type!)!, created: meal.created!, identifier: meal.identifier!, ingredients: meal.ingredients ?? [])
    }
    
    
    func deleteMeal(identifier: String) {
        let withIdentifier = NSPredicate(format: "identifier == %@", identifier)
        delete(forEntityName: "Meal", withFilter: withIdentifier)
        CoreDataManager.sharedManager.save()
    }
    

    // API Methods
    func deleteCoreData() {
        deleteBatch(ForEntityName: "Meal")
    }
}


// Private Function Helpers
extension CoreDataSingleton {
    
    // Helper Function that retrieves a specific entitiy in an Entity Store
    private func retrieve<T>(forEntityName name: String, withFilter predicate: NSPredicate) -> T? where T : NSManagedObject {
        let context = CoreDataManager.sharedManager.context
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: name)
        fetchRequest.shouldRefreshRefetchedObjects = true

        // predicate filter
        fetchRequest.predicate = predicate

        do {
            let objects = try context.fetch(fetchRequest)
            if (objects.count == 0) {
                return nil
            }

            return objects[0] as? T
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
    }

    // Retrieves all entities in an Entity Store with a filter or sort
    private func retrieveAll<T>(forEntityName name: String, sortedBy: [NSSortDescriptor]? = nil, withFilter: NSPredicate? = nil, fetchLimit: Int?=nil) -> [T]? where T : NSManagedObject {
        let context = CoreDataManager.sharedManager.context
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: name)

        if fetchLimit != nil {
            fetchRequest.fetchLimit = fetchLimit!
        }
        
        fetchRequest.shouldRefreshRefetchedObjects = true
        //        fetchRequest.returnsObjectsAsFaults = false

        if (sortedBy != nil) {
            fetchRequest.sortDescriptors = sortedBy
        }

        if (withFilter != nil) {
            fetchRequest.predicate = withFilter
        }

        do {
            let objects = try context.fetch(fetchRequest)
            return objects as? [T]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
    }

    // Batch deletes all data in an entity
    private func deleteBatch(ForEntityName entityName: String) {
        let context = CoreDataManager.sharedManager.context
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(batchDeleteRequest)
        } catch {
            print("There was an error clearing the CoreData for, \(entityName) \(error)")
        }
    }

    // Deletes entities that match the predicate
    private func delete(forEntityName name: String, withFilter predicate: NSPredicate) {
        let objs = retrieveAll(forEntityName: name, withFilter: predicate)!
        for obj in objs {
            CoreDataManager.sharedManager.context.delete(obj)
        }
        CoreDataManager.sharedManager.save()
    }
    
    
}

// CoreDataManager Singleton - creates a persistance container for CoreDataSingleton to use
private class CoreDataManager {
    static let sharedManager = CoreDataManager()
    var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private init() {} // Prevent clients from creating another instance.
    
    func save() {
        CoreDataManager.sharedManager.context.mergePolicy = NSOverwriteMergePolicy
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.saveContext()
    }
}
