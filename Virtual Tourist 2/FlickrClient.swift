//
//  FlickClient.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 27/3/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    let session: NSURLSession
    
    override private init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    let PhotosPerPage = 21
    let Precision = 0.01
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    // MARK: - Task method for GET
    
    func taskForGETMethod(parameters: [String : AnyObject], completion: (result: AnyObject?, error: ClientError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        var parameters = parameters
        parameters[URLKeys.ApiKey] = URLParamters.ApiKey
        parameters[URLKeys.NoJsonCallback] = URLParamters.NoJsonCallback
        parameters[URLKeys.DataFormat] = URLParamters.DataFormat
        parameters[URLKeys.Extras] = URLParamters.Extras
        parameters["per_page"] = PhotosPerPage
        
        
        /* 2/3. Build the URL and configure the request */
        let urlString = Constants.BaseUrl + escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            /* GUARD: Was there an error? */
            guard error == nil else {
                print("There was an error with your request: \(error)")
                completion(result: nil, error: .ErrorReturned)
                return
            }
            
//            /* GUARD: Did we get a successful 2XX response? */
//            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
//                if let response = response as? NSHTTPURLResponse {
//                    print("Your request returned an invalid response! Status code: \(response.statusCode)")
//                } else if let response = response {
//                    print("Your request returned an invalid response! Response: \(response)")
//                } else {
//                    print("Your request returned an invalid response")
//                }
//                if let data = data {
//                    print("Data: \(NSString(data: data, encoding: NSUTF8StringEncoding))")
//                }
//                completion(result: nil, error: .InvalidResponse)
//                return
//            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request")
                completion(result: nil, error: .InvalidData)
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.parseJSON(data, completion: completion)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    
    // MARK: - Task for image download
    
    func taskForImage(fileUrl: String, completion: (imageData: NSData?, error: ClientError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: fileUrl)!
        
        print(url)
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
            
            guard downloadError == nil else {
                print("There was an error with your request: \(downloadError)")
                completion(imageData: nil, error: .ErrorReturned)
                return
            }
            
            completion(imageData: data, error: nil)
            
//            if let error = downloadError {
//                let newError = TheMovieDB.errorForData(data, response: response, error: error)
//                completionHandler(imageData: nil, error: newError)
//            } else {
//                completionHandler(imageData: data, error: nil)
//            }
        }
        
        task.resume()
        
        return task
    }
}