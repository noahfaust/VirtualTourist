//
//  ClientHelper.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 27/3/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    /* Helper: Given raw JSON, return a usable Foundation object */
    func parseJSON(data: NSData, completion: (result: AnyObject!, error: ClientError?) -> Void) {
        
        /* 5. Parse the data - Part 1 */
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            print("Could not parse the data as JSON: '\(data)'")
            completion(result: nil, error: .JSONNotConverted)
        }
        
        completion(result: parsedResult, error: nil)
    }
    
    enum ClientError: ErrorType {
        case ErrorReturned
        case ImageDownloadError
        case InvalidResponse
        case InvalidCredentials
        case InvalidData
        case JSONNotConverted
        case JSONNotParsed
    }
    
}