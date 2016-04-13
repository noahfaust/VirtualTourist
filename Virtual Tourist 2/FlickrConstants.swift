//
//  FlickrConstants.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 27/3/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    struct Constants {
    
        static let BaseUrl = "https://api.flickr.com/services/rest/"
    }
    
    struct URLKeys {
        
        static let Method = "method"
        static let ApiKey = "api_key"
        static let NoJsonCallback = "nojsoncallback"
        static let DataFormat = "format"
        static let Extras = "extras"
        static let Bbox = "bbox"
        static let Page = "page"
    }
    
    struct URLParamters {
        
        static let Method = "flickr.photos.search"
        static let ApiKey = "a2c724d01bbe5ff5cae75a49d7c6eeb2"
        static let NoJsonCallback = "1"
        static let DataFormat = "json"
        static let Extras = "url_m"
    }
    
    struct JSONKeys {
        
        static let Status = "stat"
        static let Code = "code"
        static let Message = "message"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Page = "page"
        static let Pages = "pages"
        static let PerPage = "perpage"
        static let Total = "total"
    }
    
    struct StatusValues {
        
        static let Ok = "ok"
        static let Fail = "fail"
    }
    
}