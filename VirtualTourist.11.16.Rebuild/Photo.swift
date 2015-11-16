//
//  Photo.swift
//  VirtualTouristCoreData2.0
//
//  Created by new on 10/18/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//

import UIKit
import CoreData //1. import Core Data



class Photo: NSManagedObject { //2. Make Photo a subclass of NSManagedObject
	
	
	struct Keys {
    	static let ImagePath = "url_m"
	}
	
	//3. promote these two  properties to Core Data attribute
	@NSManaged var imagePath: String?
	@NSManaged var location: Location?
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context:
	  NSManagedObjectContext?) {
		
	  super.init(entity: entity, insertIntoManagedObjectContext: context)
		
	}
	
	init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
	
		//Core Data
		let entity = NSEntityDescription.entityForName("Photo",
		inManagedObjectContext: context)!
		
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	
		//Dictionary
		imagePath = dictionary[Keys.ImagePath] as? String
		
	}
		
		
	
	

 var computedLocationImage: UIImage? {
        
        get {
            return Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }
	    // MARK: - Shared Image Cache

    struct Caches {
        static let imageCache = ImageCache()
    }
}

