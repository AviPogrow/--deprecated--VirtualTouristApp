//
//  MyFlickrSearcher.swift
//  VirtualTouristCoreData2.0
//
//  Created by new on 10/20/15.
//  Copyright © 2015 Avi Pogrow. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//This class is used for the two networking calls
//1. Takes the lat and lon and returns image urls related to the location
//2. takes the image urls and download the images
//3. I added the createRandomPage function so that if the user wants a new collection
// of images they will get a different set of results
	class Flickr: NSObject {
	
  let apiKey = "fec2dca93ec5de19700fdd361f147f41"
	
  typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
  
  var session:NSURLSession
  
  override init() {
        session = NSURLSession.sharedSession()
        super.init()        
    }
  
 
		
  var latitude:NSNumber?
  var longitude:NSNumber?

  var flickrPhotoArray:[Photo]!

		
//Before making the first networking call we first need to take the longitude and latitude
  //from the selected annotation and
  // build the string and convert it to an NSURL object
  // we then use the NSURL object returned from this method and insert it into the request object
  
    func flickrSearchURLForLatLon(latitude:NSNumber?,longitude:NSNumber?) -> NSURL {
	
   let  pageNumber:Int = createRandomPageNumber()
   let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(latitude!)&lon=\(longitude!)&page=\(pageNumber)&per_page=20&extras=url_m&format=json&nojsoncallback=1"
	
	return NSURL(string:URLString)!
  }
  
   func createRandomPageNumber() -> Int {
   let randomPage = Int(arc4random_uniform(UInt32(15)))
	
	return randomPage
	}

	func searchFlickrForPhotosByLatLon(completionHandler:CompletionHandler ) -> NSURLSessionDataTask {
		
		 let url =  flickrSearchURLForLatLon(latitude,longitude:longitude)
		 let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) {data, response, downloadError in
			
		
 		if let error = downloadError  {
                print("Could not complete the request \(error)")
            } else {
			
			
		 print("Step 3 - taskForResource's completionHandler is invoked.")
	    Flickr.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
		
	
		}
	}
	task.resume()
	return task
	}
	//Mark - Task for downloading images
	
	func taskForImage(imagePath:String, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionDataTask {
		 let url = NSURL(string: imagePath)!
		 let request = NSURLRequest(URL:url)
		
		 let task = session.dataTaskWithRequest(request) {data, response, downloadError in
			if let error = downloadError {
			print("could not complete request \(error)")
			completionHandler(imageData: nil, error: error)
			
		  } else {
		   completionHandler(imageData: data, error: nil)
		
			}
		}
		
			task.resume()
		
			return task
	}


class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            print("Step 4 - parseJSONWithCompletionHandler is invoked.")
            completionHandler(result: parsedResult, error: nil)
			
		}
		
	}
}