//
//  PhotoAlbumVC.swift
//  VirtualTourist.11.16.Rebuild
//
//  Created by new on 11/16/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//
//  PhotoAlbumVC.swift
//  VirtualTourist2.3
//
//  Created by new on 10/29/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//


import UIKit
import CoreData
import MapKit

class PhotoAlbumVC: UIViewController,MKMapViewDelegate, UICollectionViewDelegate,
            UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var deleteButton: UIBarButtonItem!
	@IBOutlet weak var collectionView: UICollectionView!
	
	
	@IBAction func deleteSelectedPhotos(sender: AnyObject) {
		
		//create empty array of photos To be deleted
		var photosToDelete = [Photo]()
	
		for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
		//iterate through and delete the objects
		for photo in photosToDelete {
			
			//1 remove the photo from the application directory
			photo.computedLocationImage = nil
			
			//2 remove the imagePath from the fetchedResultsController
			self.sharedContext.deleteObject(photo)
			updateDeleteButton()
		}
			 selectedIndexes = [NSIndexPath]()
		
			//save the changes(deletions)
			dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
		
	}
	
	var selectedIndexes = [NSIndexPath]()
	
	var location:Location!
	
	let flickr = Flickr()
	
	func centerMapOnLocation() {
		// set the region
		let regionRadius: CLLocationDistance = 1000
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
		mapView.setRegion(coordinateRegion, animated: true)
		
	}
	
	
	
	
	
	// MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
	var rightAddBarButtonItem:UIBarButtonItem = UIBarButtonItem(title: "NewCollection", style: UIBarButtonItemStyle.Plain, target: self, action: "newCollection:")
		
	self.navigationItem.setRightBarButtonItems([rightAddBarButtonItem], animated: true)
 
		
		// Step 2: Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch {}
		
        // Step 6: Set the delegate to this view controller
        fetchedResultsController.delegate = self
		updateDeleteButton()
    }

	
	
	
	func newCollection (sender:UIButton) {
		
			getFlickrPhotos()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		//TODO: Add a pin to the map
		centerMapOnLocation()
		
		if location.photos.count == 0 {
		getFlickrPhotos()
		
		}
		
		}
	   func updateDeleteButton() {
        if selectedIndexes.count > 0 {
            deleteButton.enabled = true
        } else {
            deleteButton.enabled = false 
        }
    	}
	
	    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let width = floor(collectionView.frame.size.width/3) - 1
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
	

// MARK: - UICollectionView Data Source and Delegate Methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
	
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
		let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
		
		
		if  photo.computedLocationImage != nil  {
            cell.imageView.image = photo.computedLocationImage
		
		} else  if photo.imagePath == nil || photo.imagePath == "" {
			cell.imageView.image = UIImage(named: "Map")
		
		
	}      else { //if we have an imagePath but we still need to download it and save it

			//this is the network call
		let task = flickr.taskForImage(photo.imagePath!) { data, error in
		
			if let error = error {
				print("location image download error: \(error.localizedDescription)")
			}
			
			if let data = data {
			 //create the image
			 let image = UIImage(data: data)
			 
			 //update the model and store the image
			 photo.computedLocationImage = image
			 
			 //update the cell on main thread
			 dispatch_async(dispatch_get_main_queue()) {
			 	cell.imageView?.image = photo.computedLocationImage
				}
			 }
		}
	}
		
		 cell.imageView!.image = photo.computedLocationImage
	
			return cell
    }

	
	
	    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Whenever a cell is tapped we do two operations
		//1. will toggle its presence
		//  in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
  		//2.we then decide if we should make the cell grey or revert to normal
         if let index = self.selectedIndexes.indexOf(indexPath) {
            cell.imageView!.alpha = 0.5
        } else {
            cell.imageView!.alpha = 1.0
        }
		
		// if cells are selected or not selected we toggle the 
		// availability of the delete button
        updateDeleteButton()
    }
	
	
	
	 
    //MARK: - Core Data

    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
        }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
	
	//NSFetchedResultsController Delegate methods for UICollectionView
	 var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
	
	
	//1
	  func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
		}
	//2
	  func controller(controller: NSFetchedResultsController,
	didChangeObject anObject: AnyObject,
	atIndexPath indexPath: NSIndexPath?,
	forChangeType type: NSFetchedResultsChangeType,
	 newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            break
        default:
            break
        }
    }
	
	
func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
	
			//This seems the best place to put this function
			//it checks if the selectedIndex array is empty or not
			// and enables or disables the delete button
			updateDeleteButton()
    }
	
	//Mark: - networking call
	
	
	
	func getFlickrPhotos() {
		flickr.longitude = location.longitude
		flickr.latitude = location.latitude
		
		flickr.searchFlickrForPhotosByLatLon () { JSONResult, error in
			
			if let error = error {
				print(error)
			} else {
			
		if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
			
			if let photosArrayOfDictionaries = photosDictionary["photo"] as? [[String: AnyObject]] {
		
			 // Parse the array of dictionaries
			let _ = photosArrayOfDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
				let photo = Photo(dictionary: dictionary, context: self.sharedContext)
			
				photo.location = self.location
			
					return photo
				}
				
				
				dispatch_async(dispatch_get_main_queue()) {
				 CoreDataStackManager.sharedInstance().saveContext()
							}
						}
					}
				}
			}
		}
	}

	