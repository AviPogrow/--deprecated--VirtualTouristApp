//
//  PhotoCell.swift
//  VirtualTourist.11.16.Rebuild
//
//  Created by new on 11/16/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//
//  PhotoCell.swift
//  VirtualTourist2.3
//
//  Created by new on 10/29/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {


	@IBOutlet weak var imageView: UIImageView!

	@IBOutlet weak var activityView: UIActivityIndicatorView!
var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
	
	
}