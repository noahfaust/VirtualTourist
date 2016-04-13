//
//  FlickrConvenience.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 27/3/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation
import UIKit

extension FlickrClient {
    
    func getLocationPhotos(location: Location, completion: (success: Bool, errorString: String?) -> Void) {
        
        let minLatitude = location.coordinate.latitude - Precision
        let minLongitude = location.coordinate.longitude - Precision
        let maxLatitude = minLatitude + 2 * Precision
        let maxLongitude = minLongitude + 2 * Precision
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        var parameters: [String : AnyObject] = [
            URLKeys.Method: URLParamters.Method,
            URLKeys.Bbox: "\(minLongitude),\(minLatitude),\(maxLongitude),\(maxLatitude)"
        ]
        if location.lastRequestPage > 0 && location.lastRequestPage < location.lastRequestTotalPages {
            parameters[URLKeys.Page] = Int(location.lastRequestPage) + 1
        }
        
        /* 2. Make the request */
        taskForGETMethod(parameters) { result, error in
            
            guard error == nil else {
                completion(success: false, errorString: "The location photos couldn't be loaded")
                return
            }
            
            guard let result = result else {
                completion(success: false, errorString: "The location photos couldn't be loaded")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let status = result[JSONKeys.Status] as? String where status == StatusValues.Ok else {
                if let message = result[JSONKeys.Message] as? String {
                    print("Your request returned an invalid response! Status code: \(message)")
                    completion(success: false, errorString: "Your request returned an invalid response! Status code: \(message)")
                    return
                }
                completion(success: false, errorString: "error")
                return
            }
            
            guard let photosDictionary = result[JSONKeys.Photos] as? NSDictionary,
                let photosArray = photosDictionary[JSONKeys.Photo] as? [[String: AnyObject]] else {
                    print("Cannot find keys 'photos' and 'photo' in \(result)")
                    completion(success: false, errorString: "Cannot find keys 'photos' and 'photo'")
                    return
            }
            
            guard let currentPage = photosDictionary[JSONKeys.Page] as? Int else {
                print("Cannot find key 'page' in \(photosDictionary)")
                completion(success: false, errorString: "Cannot find key 'page'")
                return
            }
            
            guard let totalPages = photosDictionary[JSONKeys.Pages] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                completion(success: false, errorString: "Cannot find key 'pages'")
                return
            }
            
            // Parse the array of movies dictionaries
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                let _ = photosArray.map() { (dictionary: [String : AnyObject]) -> Photo in
                    let photo = Photo(dictionary: dictionary, context: CoreDataStackManager.sharedInstance().managedObjectContext)
                    
                    photo.location = location
                    
                    return photo
                }
                location.lastRequestPage = Int64(currentPage)
                location.lastRequestTotalPages = Int64(totalPages)
            }
                
            completion(success: true, errorString: nil)
        }
    }
    
    func downloadImage(photo: Photo, completion: (success: Bool, errorString: String?) -> Void) -> NSURLSessionTask {
        
        // Start the task that will eventually download the image
        let task = taskForImage(photo.imageUrl) { data, error in
            
            guard error == nil else {
                completion(success: false, errorString: "The photo couldn't be downloaded")
                return
            }
            
            if let data = data {
                // Craete the image
                let image = UIImage(data: data)
                
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    // update the model, so that the infrmation gets cashed
                    photo.image = image
                }
                
                completion(success: true, errorString: nil)
            }
        }
        return task
    }
}

