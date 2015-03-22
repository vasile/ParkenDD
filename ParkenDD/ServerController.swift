//
//  ServerController.swift
//  ParkenDD
//
//  Created by Kilian Költzsch on 20/02/15.
//  Copyright (c) 2015 Kilian Koeltzsch. All rights reserved.
//

import Foundation

class ServerController {

	// FIXME: Stringly typed errors? Is this Python?

	/**
	Get the current data for all parkingslots by asking the happy PHP scraper and adding a "Pretty please with sugar on top" to the request

	:param: callback (sectionNames: [String]?, parkinglotList: [Parkinglot]?, updateError: String?) -> ()
	*/
	static func sendParkinglotDataRequest(callback: (sectionNames: [String]?, parkinglotList: [Parkinglot]?, updateError: String?) -> ()) {
		let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		sessionConfig.timeoutIntervalForRequest = 15.0
		sessionConfig.timeoutIntervalForResource = 20.0
		let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

		var URL = NSURL(string: Constants.parkinglotURL)
		let request = NSMutableURLRequest(URL: URL!)
		request.HTTPMethod = "GET"

		let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
			if (error == nil) {
				// Success
				if let output = (NSString(data: data, encoding: NSUTF8StringEncoding)) {
					var parseError: NSError?
					let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError)

					// Response consists of an Array of sections, e.g. Innere Altstadt, Ring West, etc.
					if let sectionList = parsedObject as? NSArray {

						var sectionNames: [String] = []
						var parkinglotList: [Parkinglot] = []

						for section in sectionList {
							if let sectionName: String = section["name"] as? String, lots = section["lots"] as? NSArray {

								// save the section name
								sectionNames.append(sectionName)

								if lots.count == 0 {
									callback(sectionNames: nil, parkinglotList: nil, updateError: "serverError")
								}

								for lot in lots {

									// check for the main parameters
									if let lotName = lot["name"] as? String, lotCount = (lot["count"] as? String)?.toInt(), lotStateString = lot["state"] as? String {

										// the API sometimes returns the amount of free spots as an empty string if the parkinglot is closed, yay
										// but I'm still going to assume that it always exists before making this more complicated
										var lotFree: Int!
										if (lot["free"] as? String) == "" {
											lotFree = 0
										} else {
											lotFree = (lot["free"] as! String).toInt()!
										}

										// "convert" the state into the appropriate enum
										let lotState: lotstate!
										switch lotStateString {
										case "many":
											lotState = lotstate.many
										case "few":
											lotState = lotstate.few
										case "full":
											lotState = lotstate.full
										case "closed":
											lotState = lotstate.closed
										default:
											lotState = lotstate.nodata
											lotFree = -1
										}

										// hehe, lotLat is an awesome name for a variable
										if let lotLat = (lot["lat"] as? NSString)?.doubleValue, lotLon = (lot["lon"] as? NSString)?.doubleValue {
											let parkingLot = Parkinglot(section: sectionName, name: lotName, count: lotCount, free: lotFree, state: lotState, lat: lotLat, lon: lotLon, distance: nil)
											parkinglotList.append(parkingLot)
										} else {
											// apparently this lot doesn't have coordinates, which is also kind of weird
											let parkingLot = Parkinglot(section: sectionName, name: lotName, count: lotCount, free: lotFree, state: lotState, lat: nil, lon: nil, distance: nil)
											parkinglotList.append(parkingLot)
										}
									}
								}
							}
						}
						callback(sectionNames: sectionNames, parkinglotList: parkinglotList, updateError: nil)
					} else {
						callback(sectionNames: nil, parkinglotList: nil, updateError: "serverError")
					}
				} else {
					callback(sectionNames: nil, parkinglotList: nil, updateError: "serverError")
				}
			}
			else {
				// Failure
				NSLog("HTTP Request Failure: %@", error.localizedDescription)
				callback(sectionNames: nil, parkinglotList: nil, updateError: "requestError")
			}
		})
		task.resume()
	}
	
}
