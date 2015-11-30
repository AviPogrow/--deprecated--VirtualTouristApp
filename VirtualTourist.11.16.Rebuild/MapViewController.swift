//
//  MapViewController.swift
//  VirtualTourist.11.16.Rebuild
//
//  FavoriteLocationsVC.swift
//  VirtualTourist2.3
//
//  Created by new on 10/29/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class FavoriteLocationsVC: UIViewController, MKMapViewDelegate {

	
	@IBOutlet weak var mapView: MKMapView!
	
	
	
	var deleteMode:Bool!
	
	var locations = [Location]()
	var location:Location!
	
	var sharedContext: NSManagedObjectContext {
	 return CoreDataStackManager.sharedInstance().managedObjectContext
	 }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Done, target: self, action: "toggleDeleteMode")
		
	
		//set initial location
		let initialLocation = CLLocation(latitude: 40.828819, longitude: -73.926569)
		centerMapOnLocation(initialLocation)
	
	let pressGestureRecognizer =
		UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
		mapView.addGestureRecognizer(pressGestureRecognizer)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		updateLocations()
	}
	
	func toggleDeleteMode(){
		print("toggle button pressed")
	}
	
	
	
	
	func centerMapOnLocation(initialLocation: CLLocation) {
		// set the region
		let regionRadius: CLLocationDistance = 1000
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius, regionRadius)
		mapView.setRegion(coordinateRegion, animated: true)
		
	}






	//MARK: This method does the following 8 things
 
	func handleLongPress(pressGestureRecognizer : UIGestureRecognizer) {
	
		if pressGestureRecognizer.state != .Began { return }

    let touchPoint = pressGestureRecognizer.locationInView(self.mapView)
    let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

	let annotation = MKPointAnnotation()
	annotation.coordinate = touchMapCoordinate

    mapView.addAnnotation(annotation)
	
	//create a dictionary for the new location to be added to the context
	
	let dictionary: [String: AnyObject] = [
	  Location.Keys.longitude: annotation.coordinate.longitude,
	  Location.Keys.latitude: annotation.coordinate.latitude,
	  Location.Keys.flickrPageToFetch:  1
	  ]
	
	
		//5. Use the dictionary and context to create new instance of location entity
		//object and insert it in the context
		location = Location(dictionary: dictionary, context: sharedContext)
	
		//6. add it to the array of location objects
		self.locations.append(location)
	
		//7.  save the shared Context
		CoreDataStackManager.sharedInstance().saveContext()
	
		//8.  fetch the location objects from the context and populate the mapView
		//with pins
		updateLocations()
	
		//8. prefetch the photos for the next screen and store them in coreData
		getFlickrPhotos()
	
		}
	

	func showLocationDetails(sender: UIButton) {
		
		performSegueWithIdentifier("ShowLocationPhotos", sender: sender)
		
		}

	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
		if segue.identifier == "ShowLocationPhotos" {
		
		let controller = segue.destinationViewController as! PhotoAlbumVC
		
	  	let button = sender as! UIButton
		
		controller.location = locations[button.tag]
		}
	}
	
	
	//MARK: Set Up MapView View objects the Pin and the Callout buttn
	
	var annotationView: MKPointAnnotation!
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		
		guard annotation is Location else {
			
			return nil
    	}
    
    	let identifier = "Location"
		var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as! MKPinAnnotationView!
		
		if annotationView == nil {
			
		annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      
		
		annotationView.enabled = true
		annotationView.canShowCallout = true
		annotationView.animatesDrop = false
      	annotationView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
      	annotationView.draggable = false
		
		
		
		let rightButton = UIButton(type: .DetailDisclosure)
		rightButton.addTarget(self, action: Selector("showLocationDetails:"), forControlEvents: .TouchUpInside)
		annotationView.rightCalloutAccessoryView = rightButton
		
		} else {
		
		annotationView.annotation = annotation
    	}
    
    	let button = annotationView.rightCalloutAccessoryView as! UIButton
    	if let index = locations.indexOf(annotation as! Location) {
		button.tag = index
		}
    
    		return annotationView
 	 }

	func updateLocations() {
		
		mapView.removeAnnotations(locations)
    
		let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: sharedContext)
    
		let fetchRequest = NSFetchRequest()
		
		fetchRequest.entity = entity
		
		locations = try! sharedContext.executeFetchRequest(fetchRequest) as! [Location]
		
		mapView.addAnnotations(locations)
		}
	
	
	//Mark: - networking call
	
	var flickr = Flickr()
	
	
	func getFlickrPhotos() {
		flickr.longitude = location.longitude
		flickr.latitude = location.latitude
		flickr.pageToFetch = location.flickrPageToFetch++
		
			dispatch_async(dispatch_get_main_queue()) {
			CoreDataStackManager.sharedInstance().saveContext()
		}
	
		flickr.newSearchFlickrForPhotosByLatLon () { JSONResult, error in
			
			if let error = error {
				
				print(error)
			
			} else {
			
		if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
		
		if let photosArrayOfDictionaries = photosDictionary["photo"] as? [[String: AnyObject]] {
		
			dispatch_async(dispatch_get_main_queue()) {
		
		let _ = photosArrayOfDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
			
			let photo = Photo(dictionary: dictionary, context: self.sharedContext)
			
				photo.location = self.location
			
					
					return photo
				}

				CoreDataStackManager.sharedInstance().saveContext()
				
						}
					}
				}
			}
		}
	}
}	
	
	
	
	
	
	
	
	
	
	
	
