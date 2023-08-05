//
//  CoreData.swift
//  Travel
//
//  Created by Terry Jason on 2023/8/3.
//

import UIKit
import CoreData

func createContext() -> NSManagedObjectContext {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    return appDelegate.persistentContainer.viewContext
}

func saveData() -> NSManagedObject{
    let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: createContext())
    return newPlace
}

func setDataValue(name: String, note: String, latitude: Double, longitude: Double) {
    let newLocation = saveData()
    
    newLocation.setValue(name, forKey: "title")
    newLocation.setValue(note, forKey: "subtitle")
    newLocation.setValue(latitude, forKey: "latitude")
    newLocation.setValue(longitude, forKey: "longitude")
    newLocation.setValue(UUID(), forKey: "id")
    
    contextSave()
}

func contextSave() {
    do {
        try createContext().save()
    } catch {
        print("有錯誤")
    }
}

func fetchData() -> NSFetchRequest<NSFetchRequestResult> {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
    
    request.returnsObjectsAsFaults = false
    return request
}

func fetchDataWithId(id: String) -> NSFetchRequest<NSFetchRequestResult> {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
    
    fetchRequest.predicate = NSPredicate(format: "id = %@", id)
    fetchRequest.returnsObjectsAsFaults = false
    
    return fetchRequest
}
