//
//  LibraryDetailViewController.swift
//  berkeleyMobileiOS
//
//  Created by Sampath Duddu on 11/13/16.
//  Copyright © 2016 org.berkeleyMobile. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps

fileprivate let kLibraryCellHeight: CGFloat = 125.0

class LibraryDetailViewController: UIViewController, IBInitializable, GMSMapViewDelegate, CLLocationManagerDelegate, ResourceDetailProvider, UITableViewDelegate, UITableViewDataSource {
    
    
    
    @IBOutlet weak var LibraryTableView: UITableView!
    
    @IBOutlet var libraryDetailView: UIView!
   
    @IBOutlet var libraryStartEndTime: UILabel!
    @IBOutlet var libraryStatus: UILabel!
    @IBOutlet var libraryImage: UIImageView!
    @IBOutlet var libraryDetailTableView: UITableView!
    @IBOutlet var libraryMapView: GMSMapView!
    @IBOutlet var libraryName: UILabel!
    @IBOutlet var libraryAddress: UIButton!
    
    var library: Library!
    var locationManager = CLLocationManager()
    
    
    // MARK: - IBInitalizable
    typealias IBComponent = LibraryDetailViewController
    
    static var componentID: String { return className(IBComponent.self) }
    
    static func fromIB() -> IBComponent
    {
        return UIStoryboard.academics.instantiateViewController(withIdentifier: self.componentID) as! IBComponent
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 50.0;//Choose your custom row height
    }
    
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LibraryTableView.dataSource = self
        LibraryTableView.delegate = self
        //libraryImage.sd_setImage(with: library?.imageURL!)
        setUpMap()
        setUpInformation();
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = LibraryTableView.dequeueReusableCell(withIdentifier: "LibCell") as! LibraryOptionCell
        
        if (indexPath.row == 0) {
            cell.NewImage.image = #imageLiteral(resourceName: "phone")
        }
        if (indexPath.row == 1) {
            cell.NewImage.image = #imageLiteral(resourceName: "heart")
            
            if library.isFavorited {
                cell.NewImage.image = #imageLiteral(resourceName: "heart_filled")
            } else {
                cell.NewImage.image = #imageLiteral(resourceName: "heart")
            }
        }
        if (indexPath.row == 2) {
            cell.NewImage.image = #imageLiteral(resourceName: "website")
        }
        
        
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            //cell.NewImage.image = #imageLiteral(resourceName: "phone")
            
            let numberArray = self.library?.phoneNumber?.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
            var number = ""
            for n in numberArray! {
                number += n
            }
            
            if let url = URL(string: "telprompt://\(number)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            
            
        }
        if (indexPath.row == 1) {
            //cell.NewImage.image = #imageLiteral(resourceName: "heart")
            
            guard let library = self.library else {
                return
            }
            library.isFavorited = !library.isFavorited
            FavoriteStore.shared.update(library)
            LibraryTableView.reloadData()
            
           
            
            
            
        }
        if (indexPath.row == 2) {
            //cell.NewImage.image = #imageLiteral(resourceName: "website")
            
            
             UIApplication.shared.open(NSURL(string: "http://www.lib.berkeley.edu/libraries/main-stacks")! as URL,  options: [:], completionHandler: nil)
            
            
        }
    }
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpInformation() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        
        if (self.library?.weeklyClosingTimes[0] == nil) {
            self.libraryStartEndTime.text = ""
            self.libraryStatus.text = "Closed"
            self.libraryStatus.textColor = UIColor.red
            
        } else {
            let localOpeningTime = dateFormatter.string(from: (self.library?.weeklyOpeningTimes[0])!)
            let localClosingTime = dateFormatter.string(from: (self.library?.weeklyClosingTimes[0])!)
            
            self.libraryStartEndTime.text = localOpeningTime + " to " + localClosingTime
            
            //Calculating whether the library is open or not
            var status = "Open"
            if (self.library?.weeklyClosingTimes[0]?.compare(NSDate() as Date) == .orderedAscending) {
                status = "Closed"
            }
            self.libraryStatus.text = status
            if (status == "Open") {
                self.libraryStatus.textColor = UIColor.green
            } else {
                self.libraryStatus.textColor = UIColor.red
            }
        }
    
        // For favoriting
      
    }

    


    @IBAction func viewLibraryMap(_ sender: Any) {
        
        let lat = library?.latitude!
        let lon = library?.longitude!
        
        UIApplication.shared.open(NSURL(string: "https://www.google.com/maps/dir/Current+Location/" + String(describing: lat!) + "," + String(describing: lon!))! as URL,  options: [:], completionHandler: nil)

    }
    
    func setUpMap() {
        //Setting up map view
        libraryMapView.delegate = self
        libraryMapView.isMyLocationEnabled = true
        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
        self.libraryMapView.camera = camera
        self.libraryMapView.frame = self.view.frame
        self.libraryMapView.isMyLocationEnabled = true
        self.libraryMapView.delegate = self
        self.locationManager.startUpdatingLocation()
        
        let kMapStyle =
            "[" +
                "{ \"featureType\": \"administrative\", \"elementType\": \"geometry\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"poi\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"road\", \"elementType\": \"labels.icon\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"transit\", \"stylers\": [ {  \"visibility\": \"off\" } ] } " +
        "]"
        
        do {
            // Set the map style by passing a valid JSON string.
            self.libraryMapView.mapStyle = try GMSMapStyle(jsonString: kMapStyle)
        } catch {
            NSLog("The style definition could not be loaded: \(error)")
//            print(error)
        }
        
        let lat = library?.latitude!
        let lon = library?.longitude!
        let marker = GMSMarker()
        
        marker.position = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
        marker.title = library?.name
        
        let status = library?.isOpen;
        if status! {
            marker.icon = GMSMarker.markerImage(with: .green)
            marker.snippet = "Open"
        } else {
            marker.icon = GMSMarker.markerImage(with: .red)
            marker.snippet = "Closed"
            
        }
        marker.map = self.libraryMapView

    }


    // MARK: - ResourceDetailProvider
    static func newInstance() -> ResourceDetailProvider {
        return fromIB()
    }
    
    var resource: Resource
    {
        get { return library }
        set
        {
            if viewIfLoaded == nil, library == nil, let newLibrary = newValue as? Library
            {
                library = newLibrary
                title = library.name
            }
        }
    }
    
    var text1: String? {
        return nil
    }
    var text2: String? {
        return nil
    }
    var viewController: UIViewController {
        return self
    }
    var imageURL: URL? {
        return library?.imageURL
    }
    
    var resetOffsetOnSizeChanged = false
    
    var buttons: [UIButton]
    {
        return []
    }
    
    var contentSizeChangeHandler: ((ResourceDetailProvider) -> Void)?
        {
        get { return nil }
        set {}
    }
    
    /// Get the contentSize property of the internal UIScrollView.
    var contentSize: CGSize
    {
        let width = view.bounds.width
        let height = libraryDetailView.height + libraryMapView.height
        return CGSize(width: width, height: height)
        
    }
    
    /// Get/Set the contentOffset property of the internal UIScrollView.
    var contentOffset: CGPoint
        {
        get { return CGPoint.zero }
        set {}
    }
    
    /// Set of setContentOffset method of the internal UIScrollView.
    func setContentOffset(_ offset: CGPoint, animated: Bool){}
    
    
    
}
