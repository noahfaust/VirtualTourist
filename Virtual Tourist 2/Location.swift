//
//  PinAnnotation.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 26/3/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Location: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var lastRequestPage: Int64
    @NSManaged var lastRequestTotalPages: Int64
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(pinLatitude: Double, pinLongitude: Double, context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        latitude = pinLatitude
        longitude = pinLongitude
        
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
