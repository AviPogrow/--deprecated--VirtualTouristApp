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
	
	
	var selectedIndexes = [NSIndexPath]()
	
	var location:Location!
	
	let flickr = Flickr()
	
	
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

	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		//TODO: Add a pin to the map
		centerMapOnLocation()
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
	
	func centerMapOnLocation() {
		// set the region
		let regionRadius: CLLocationDistance = 1000
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
		mapView.setRegion(coordinateRegion, animated: true)
		
	}
	
	func newCollection (sender:UIButton) {
		
		deleteAllPictures()
		
		getFlickrPhotos()
	}

	func updateDeleteButton() {
        if selectedIndexes.count > 0 {
            deleteButton.enabled = true
        } else {
            deleteButton.enabled = false 
        }
	}

 	@IBAction func deleteSelectedPhotos(sender: AnyObject) {
		
		//create empty array of photos To be deleted
		var photosToDelete = [Photo]()
	
		//iterate through the selectedIndex index values and append each one
		// to the photosToDelete array
		for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
		//iterate through the photosToDelete array
		for photo in photosToDelete {
			
			//1 remove the photo from the application directory
			photo.prepareForDeletion()
			
			//2 remove the image metaData from the fetchedResultsController
			self.sharedContext.deleteObject(photo)
			updateDeleteButton()
		}
			 selectedIndexes = [NSIndexPath]()
		
			//save the changes(deletions)
			dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
		
	}
 
 
	// Delete all images in photos array
    func deleteAllPictures() {
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
			
			//this method should get called automatically
			//removes the photos from documents directory
			photo.prepareForDeletion()
			
			//remove the photo metaData from core data
			self.sharedContext.deleteObject(photo)
			
			updateDeleteButton()
        }
		 	selectedIndexes = [NSIndexPath]()
		
			//save the changes(deletions)
			dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
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
		
		cell.activityView.startAnimating()
		
		configureCell(cell, atIndexPath: indexPath)
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
		//2. call a method to toggle the transparency of the cell
		configureCell(cell, atIndexPath: indexPath)
		
		//TODO: update the bottom button
		updateDeleteButton()
		
		}
	
	
	//step1. pass the custom cell and indexPath into the method
	func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
		
		//the image that will populate the imageView
		var finalImage = UIImage()
		
		//cell.imageView!.image = nil
		
		//step 2. use the indexPath to get the model photo object from the FRC
		let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
	
		//if we have a stored image then we use it to populate the view
		if  photo.computedLocationImage != nil  {
            cell.imageView.image = photo.computedLocationImage
			cell.activityView.stopAnimating()
		}
			
	   else { //if we have an imagePath but we still need to download it and save it

			//ask flickr for the image at the URL
		let task = flickr.taskForImage(photo.flickrImageURL!) { data, error in
		
			if let error = error {
				print("location image download error: \(error.localizedDescription)")
			}
			//Get back the main thread to access the core data context and the UI
			 dispatch_async(dispatch_get_main_queue()) {
			
			 if let data = data {
			 //create the image
			 let image = UIImage(data: data)
			 
			 //update the model and store the image
			 photo.computedLocationImage = image
			 
			 
			
			 	cell.activityView.stopAnimating()
			 	cell.imageView?.image = photo.computedLocationImage
				}
			 }
		}
	}
	
		 cell.imageView!.image = photo.computedLocationImage
		  
		if let index = self.selectedIndexes.indexOf(indexPath) {
            cell.imageView!.alpha = 0.5
        } else {
            cell.imageView!.alpha = 1.0
        }
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
	//set the three empty arrays that will store the indexPath that need to be modified
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
	
			updateDeleteButton()
    	}
	
	//Mark: - networking call
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
			
		//get the main thread to access the shared context and the UI
		dispatch_async(dispatch_get_main_queue()) {
		
		if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
		
		if let photosArrayOfDictionaries = photosDictionary["photo"] as? [[String: AnyObject]] {
		
		
		// Parse the array of dictionaries
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

	

	


			


	