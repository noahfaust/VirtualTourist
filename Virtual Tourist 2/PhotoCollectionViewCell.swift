//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 11/4/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation
import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    // The property uses a property observer. Any time its
    // value is set it canceles the previous NSURLSessionTask
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    
    func setImage(image: UIImage?) {
        // Set the frame of the cell according to its size: Solve issue of label being misplace at first load
        self.contentView.frame = self.bounds
        
        if let image = image {
            loadingView.stopAnimating()
            loadingView.hidden = true
            backgroundView = UIImageView(image: image)
            backgroundView!.contentMode = .ScaleAspectFill
        } else {
            backgroundView = nil
            loadingView.hidden = false
            loadingView.startAnimating()
        }
    }
}
