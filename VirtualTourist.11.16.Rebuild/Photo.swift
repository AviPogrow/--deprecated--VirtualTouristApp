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
    	static let FlickrImageURL = "url_m"
		static let ID = "id"
        static let Secret = "secret"
	}
	
	//3. promote these two  properties to Core Data attribute
	@NSManaged var flickrImageURL: String?
	@NSManaged var id : String
    @NSManaged var secret : String
	@NSManaged var location: Location?
	
	 var imageIdentifier: String {
   	 return "\(id)_\(secret)_m.jpg"
	}
	
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
		flickrImageURL = dictionary[Keys.FlickrImageURL] as? String
		id = dictionary[Keys.ID] as! String
		secret = dictionary[Keys.Secret] as! String
		
	
	}
		
	var computedLocationImage: UIImage? {
        
        get {
            return Caches.imageCache.imageWithIdentifier(imageIdentifier)
        }
        
        set {
            Caches.imageCache.storeImage(newValue, withIdentifier: imageIdentifier)
        }
    }
	  override func prepareForDeletion() {
        computedLocationImage = nil
    }
	
	
	// MARK: - Shared Image Cache

    struct Caches {
        static let imageCache = ImageCache()
    }
}

