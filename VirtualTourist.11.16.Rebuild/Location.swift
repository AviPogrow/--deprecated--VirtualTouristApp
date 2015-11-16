
//  Location.swift
//  VirtualTourist2.3
//
//  Created by new on 11/13/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation {

	@NSManaged var latitude: Double
	@NSManaged var longitude: Double
	@NSManaged var photos: [Photo]

	struct Keys {
		static let latitude = "latitude"
		static let longitude = "longitude"
	}
 
	
 var coordinate: CLLocationCoordinate2D {
   	 return CLLocationCoordinate2DMake(latitude, longitude)
	}
	
	 var title: String? {
		
      return "\(longitude)"
    }
	
//4. include this standard init method
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext
  context: NSManagedObjectContext?) {
  	super.init(entity: entity, insertIntoManagedObjectContext: context)
	
  }
  //5. The two argument init method with two goals
  // a. insert the new Location into a Core Data context
  // b. initialize the Location's properties from a dictionary
   init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {

	//Get the entity associated with the "Pin" type. The entity contains the information
	// from the Model.xcdatamodeld file
	let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!

	
	//take the context that was passed in as a parameter and insert our entity object
	// into the context
	super.init(entity: entity, insertIntoManagedObjectContext: context)

   // after the Pin is inserted into core data we then set the attribute values
   // from the dictionary that was passed as a parameter
   longitude = dictionary[Keys.longitude] as! Double
	
    latitude = dictionary [Keys.latitude] as! Double
	
	CoreDataStackManager.sharedInstance().saveContext()	
	}
}