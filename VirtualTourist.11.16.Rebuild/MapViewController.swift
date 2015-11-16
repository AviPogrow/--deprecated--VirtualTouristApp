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
	
	var locations = [Location]()
	
	
	var sharedContext: NSManagedObjectContext {
	 return CoreDataStackManager.sharedInstance().managedObjectContext
	 }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.leftBarButtonItem = self.editButtonItem()
	
	
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
	
	
	
	
func centerMapOnLocation(initialLocation: CLLocation) {
		// set the region
		let regionRadius: CLLocationDistance = 1000
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius, regionRadius)
		mapView.setRegion(coordinateRegion, animated: true)
		
	}
func handleLongPress(getstureRecognizer : UIGestureRecognizer){
    if getstureRecognizer.state != .Began { return }

    let touchPoint = getstureRecognizer.locationInView(self.mapView)
    let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

	let annotation = MKPointAnnotation()
	annotation.coordinate = touchMapCoordinate

    mapView.addAnnotation(annotation)
	
	//create a dictionary for the new location to be added to the context
	
	let dictionary: [String: AnyObject] = [
	  Location.Keys.longitude: annotation.coordinate.longitude,
	  Location.Keys.latitude: annotation.coordinate.latitude
	  ]
	
	
	// Use the dictionary and context to create new Location
	let locationToBeAdded = Location(dictionary: dictionary, context: sharedContext)
	
	self.locations.append(locationToBeAdded)
	
	//Finally we save the shared Context
	CoreDataStackManager.sharedInstance().saveContext()
	
	updateLocations()
	}


	

	  func showPhotoAlbum(sender: UIButton) {
    performSegueWithIdentifier("ShowLocationPhotos", sender: sender)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowLocationPhotos" {
      let controller = segue.destinationViewController as! PhotoAlbumVC
		
		
      
      let button = sender as! UIButton
      controller.location = locations[button.tag]
		
    }
  }
	
	
	
	
	
	
	
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
      
      let rightButton = UIButton(type: .DetailDisclosure)
      rightButton.addTarget(self, action: Selector("showPhotoAlbum:"), forControlEvents: .TouchUpInside)
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
}