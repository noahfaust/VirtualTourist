//
//  Photo.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 26/3/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Photo: NSManagedObject {
    
    struct Keys {
        static let Id = "id"
        static let Title = "title"
        static let ImageUrl = "url_m"
    }
    
    @NSManaged var id: String
    @NSManaged var title: String?
    @NSManaged var imageUrl: String
    @NSManaged var imagePath: String?
    @NSManaged var location: Location?
    var imageDownloaded: Bool = false
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        id = dictionary[Keys.Id] as! String
        title = dictionary[Keys.Title] as? String
        imageUrl = dictionary[Keys.ImageUrl] as! String
    }
    
    var image: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(id)
        }
        
        set {
            imagePath = FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: id)
            imageDownloaded = true
        }
    }
    
    override func prepareForDeletion() {
        print("Delete image with id: \(id)")
        if let _ = self.imagePath {
            FlickrClient.Caches.imageCache.storeImage(nil, withIdentifier: id)
        }
        super.prepareForDeletion()
    }
    
}
