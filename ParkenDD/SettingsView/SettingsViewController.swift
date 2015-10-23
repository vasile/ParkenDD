//
//  SettingsViewController.swift
//  ParkenDD
//
//  Created by Kilian Költzsch on 17/03/15.
//  Copyright (c) 2015 Kilian Koeltzsch. All rights reserved.
//

import UIKit
import Social
import MessageUI
import SwiftyDrop
import CoreLocation
import Crashlytics

enum Sections: Int {
	case cityOptions = 0
	case sortingOptions
	case displayOptions
	case otherOptions
}

class SettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

		let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismiss")
		self.navigationItem.rightBarButtonItem = doneButton

		self.navigationItem.title = L10n.SETTINGS.string
		let font = UIFont(name: "AvenirNext-Medium", size: 18.0)
		var attrsDict = [String: AnyObject]()
		attrsDict[NSFontAttributeName] = font
		self.navigationController?.navigationBar.titleTextAttributes = attrsDict
    }

	func dismiss() {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	override func viewWillAppear(animated: Bool) {
		tableView.reloadData()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sec = Sections(rawValue: section)!
		switch sec {
		case .cityOptions:
			return 1
		case .sortingOptions:
			return 5
		case .displayOptions:
			return 3
		case .otherOptions:
			return 4
		}
    }

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let sec = Sections(rawValue: section)!
		switch sec {
		case .cityOptions:
			return L10n.CITYOPTIONS.string
		case .sortingOptions:
			return L10n.SORTINGOPTIONS.string
		case .displayOptions:
			return L10n.DISPLAYOPTIONS.string
		case .otherOptions:
			return L10n.OTHEROPTIONS.string
		}
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let sec = Sections(rawValue: indexPath.section)!
		let cell: UITableViewCell = UITableViewCell()

		let selectedCity = NSUserDefaults.standardUserDefaults().stringForKey(Defaults.selectedCity)
		let sortingType = NSUserDefaults.standardUserDefaults().stringForKey(Defaults.sortingType)
		let doHideLots = NSUserDefaults.standardUserDefaults().boolForKey(Defaults.skipNodataLots)
		let useGrayscale = NSUserDefaults.standardUserDefaults().boolForKey(Defaults.grayscaleUI)
        let showExperimentalCities = NSUserDefaults.standardUserDefaults().boolForKey(Defaults.showExperimentalCities)

		switch (sec, indexPath.row) {
		// CITY OPTIONS
		case (.cityOptions, 0):
			cell.textLabel!.text = selectedCity
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

		// SORTING OPTIONS
		case (.sortingOptions, 0):
			cell.textLabel?.text = L10n.SORTINGTYPEDEFAULT.string
			cell.accessoryType = sortingType == Sorting.standard ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		case (.sortingOptions, 1):
			cell.textLabel?.text = L10n.SORTINGTYPELOCATION.string
			cell.accessoryType = sortingType == Sorting.distance ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		case (.sortingOptions, 2):
			cell.textLabel?.text = L10n.SORTINGTYPEALPHABETICAL.string
			cell.accessoryType = sortingType == Sorting.alphabetical ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		case (.sortingOptions, 3):
			cell.textLabel?.text = L10n.SORTINGTYPEFREESPOTS.string
			cell.accessoryType = sortingType == Sorting.free ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		case (.sortingOptions, 4):
			cell.textLabel!.text = L10n.SORTINGTYPEEUKLID.string
			cell.accessoryType = sortingType == Sorting.euclid ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None

		// DISPLAY OPTIONS
		case (.displayOptions, 0):
			cell.textLabel?.text = L10n.HIDENODATALOTS.string
			cell.accessoryType = doHideLots ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		case (.displayOptions, 1):
			cell.textLabel?.text = L10n.USEGRAYSCALECOLORS.string
			cell.accessoryType = useGrayscale ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        case (.displayOptions, 2):
            cell.textLabel?.text = L10n.SHOWEXPERIMENTALCITIESSETTING.string
            cell.accessoryType = showExperimentalCities ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None

		// OTHER OPTIONS
		case (.otherOptions, 0):
			cell.textLabel?.text = L10n.EXPERIMENTALPROGNOSIS.string
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		case (.otherOptions, 1):
			cell.textLabel?.text = L10n.ABOUTBUTTON.string
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		case (.otherOptions, 2):
			cell.textLabel?.text = L10n.SHAREONTWITTER.string
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		case (.otherOptions, 3):
			cell.textLabel?.text = L10n.SENDFEEDBACK.string
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

		default:
			break
		}

		cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16.0)
		return cell

	}

	// MARK: - Table View Delegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let sec = Sections(rawValue: indexPath.section)!

		var answersParams: [String: AnyObject]?

		switch sec {
		// CITY OPTIONS
		case .cityOptions:
			answersParams = ["section": "cityOptions"]
			performSegueWithIdentifier("showCitySelection", sender: self)

		// SORTING OPTIONS
		case .sortingOptions:

			// Don't let the user select a location based sorting option if the required authorization is missing
			if indexPath.row == 1 || indexPath.row == 4 {
				if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
					let alertController = UIAlertController(title: L10n.LOCATIONDATAERRORTITLE.string, message: L10n.LOCATIONDATAERROR.string, preferredStyle: UIAlertControllerStyle.Alert)
					alertController.addAction(UIAlertAction(title: L10n.CANCEL.string, style: UIAlertActionStyle.Cancel, handler: nil))
					alertController.addAction(UIAlertAction(title: L10n.SETTINGS.string, style: UIAlertActionStyle.Default, handler: {
						(action) in
						UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
					}))
					presentViewController(alertController, animated: true, completion: nil)

					tableView.deselectRowAtIndexPath(indexPath, animated: true)
					return
				}
			}

			for row in 0...4 {
				tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: Sections.sortingOptions.rawValue))?.accessoryType = UITableViewCellAccessoryType.None
			}
			tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark

			var defaultsValue: String
			switch indexPath.row {
			case 1:
				answersParams = ["section": "sortingOptions", "row": "sortingDistance"]
				defaultsValue = Sorting.distance
			case 2:
				answersParams = ["section": "sortingOptions", "row": "sortingAlphabetical"]
				defaultsValue = Sorting.alphabetical
			case 3:
				answersParams = ["section": "sortingOptions", "row": "sortingFree"]
				defaultsValue = Sorting.free
			case 4:
				answersParams = ["section": "sortingOptions", "row": "sortingEuklid"]
				defaultsValue = Sorting.euclid
			default:
				answersParams = ["section": "sortingOptions", "row": "sortingDefault"]
				defaultsValue = Sorting.standard
			}
			NSUserDefaults.standardUserDefaults().setValue(defaultsValue, forKey: Defaults.sortingType)

		// DISPLAY OPTIONS
		case .displayOptions:
			switch indexPath.row {
			case 0:
				let doHideLots = NSUserDefaults.standardUserDefaults().boolForKey(Defaults.skipNodataLots)
				if doHideLots {
					answersParams = ["section": "displayOptions", "row": "skipNodataLotsDisabled"]
					NSUserDefaults.standardUserDefaults().setBool(false, forKey: Defaults.skipNodataLots)
					tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
				} else {
					answersParams = ["section": "displayOptions", "row": "skipNodataLotsEnabled"]
					NSUserDefaults.standardUserDefaults().setBool(true, forKey: Defaults.skipNodataLots)
					tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
				}
				refreshLotlist()
			case 1:
				let useGrayscale = NSUserDefaults.standardUserDefaults().boolForKey(Defaults.grayscaleUI)
				if useGrayscale {
					NSUserDefaults.standardUserDefaults().setBool(false, forKey: Defaults.grayscaleUI)
					answersParams = ["section": "displayOptions", "row": "grayscaleDisabled"]
					tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
				} else {
					NSUserDefaults.standardUserDefaults().setBool(true, forKey: Defaults.grayscaleUI)
					answersParams = ["section": "displayOptions", "row": "grayscaleEnabled"]
					tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
				}
            case 2:
                let showExperimentalCities = NSUserDefaults.standardUserDefaults().boolForKey(Defaults.showExperimentalCities)
                if showExperimentalCities {
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: Defaults.showExperimentalCities)
                    tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
                    refreshLotlist()
                } else {
                    let alert = UIAlertController(title: L10n.NOTETITLE.string, message: L10n.SHOWEXPERIMENTALCITIESALERT.string, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: L10n.CANCEL.string, style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                        
                    }))
                    alert.addAction(UIAlertAction(title: L10n.ACTIVATE.string, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: Defaults.showExperimentalCities)
                        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
                        refreshLotlist()
                    }))
                    presentViewController(alert, animated: true, completion: nil)
                }
			default:
				break
			}

		// OTHER OPTIONS
		case .otherOptions:
			switch indexPath.row {
			case 0:
				answersParams = ["section": "otherOptions", "row": "showPrognosisView"]
				performSegueWithIdentifier("showPrognosisView", sender: self)
			case 1:
				answersParams = ["section": "otherOptions", "row": "showAboutView"]
				performSegueWithIdentifier("showAboutView", sender: self)
			case 2:
				answersParams = ["section": "otherOptions", "row": "presentTweetComposer"]
				if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
					let tweetsheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
					tweetsheet.setInitialText(L10n.TWEETTEXT.string)
					self.presentViewController(tweetsheet, animated: true, completion: nil)
				}
			case 3:
				answersParams = ["section": "otherOptions", "row": "presentMailComposer"]
				if MFMailComposeViewController.canSendMail() {
					let mail = MFMailComposeViewController()
					mail.mailComposeDelegate = self

					let versionNumber: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
					mail.setSubject("[ParkenDD v\(versionNumber)] Feedback")
					mail.setToRecipients(["parkendd@kilian.io"])

					self.presentViewController(mail, animated: true, completion: nil)
				}
			default:
				break
			}
		}

		if let answersParams = answersParams {
			Answers.logCustomEventWithName("User Settings", customAttributes: answersParams)
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	// MARK: - MFMailComposeViewControllerDelegate

	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

}

func refreshLotlist() -> Void {
    if let lotlistVC = UIApplication.sharedApplication().keyWindow?.rootViewController?.childViewControllers[0] as? LotlistViewController {
        lotlistVC.updateData()
    }
}
