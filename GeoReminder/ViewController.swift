//
//  ViewController.swift
//  GeoPin
//
//  Created by Patrick Li on 7/29/17.
//  Copyright © 2017 Dali Labs, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import CoreLocation
import MapKit
import SceneKit
import KLCPopup
import SceneKit 
import MessageUI

extension UIView {
    class func loadFromNibNamed(nibNamed: String, bundle : Bundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
            ).instantiate(withOwner: nil, options: nil)[0] as? UIView
    }
}

@IBDesignable class MultSelectView : UIView
{
    var parentViewController: ViewController?
    @IBAction func segueToDirections(_ sender: Any) {
        let nvc = self.parentViewController!.storyboard?.instantiateViewController(withIdentifier: "nav") as! NavigateViewController
        nvc.itemAnnotation = parentViewController!.currLoc
        self.parentViewController!.navigationController?.pushViewController(nvc, animated: true)
    }
    @IBAction func BountyScreen(_ sender: Any) {
        parentViewController!.segueToBounty()
    }

    @IBAction func deletePressed(_ sender: Any) {
        parentViewController?.deletePin()
        KLCPopup.dismissAllPopups()
    }


    class func instanceFromNib() -> UIView {
        return UINib(nibName: "MultSelectView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }

}

@IBDesignable class BountyPopup : UIView, MFMessageComposeViewControllerDelegate
{
    var parentViewController: ViewController?
    @IBAction func segueToDirections(_ sender: Any) {
    }
    
    @IBAction func BountyScreen(_ sender: Any) {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        // Configure the fields of the interface.
        composeVC.recipients = [parentViewController!.lastBountyPin.phoneNumber!]
        // Present the view controller modally.
        self.parentViewController!.navigationController?.pushViewController(composeVC, animated: true)
    }
    
    @IBAction func deletePressed(_ sender: Any) {
      
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "BountyPopup", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        // Check the result or perform other tasks.

        // Dismiss the message compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
}

class MapPoint {
    var location: CLLocation!
    var id: String!

    init (loc: CLLocation, pinID: String){
        location = loc
        id = pinID
    }
}

class MyAnnotation: NSObject, MKAnnotation{
    var coordinate: CLLocationCoordinate2D
    var id: String!

    init (loc: CLLocation, pinID: String){
        id = pinID
        coordinate = loc.coordinate

        super.init()
    }
}

class ViewController: UIViewController, MKMapViewDelegate, SceneLocationViewDelegate {
    //map
    var regPins = [MapPoint]()
    var bountyPins = [CLLocation]()
    var currLoc: MyAnnotation!
    var selectedID: String!

    //klc popup
    var popup : KLCPopup!

    var usedValues : [String] = []

    //user
    var userID: String = "jdinlkj392djf"
    
    //firebase
    var ref: DatabaseReference!

    var lastBountyPin: BountyAnnotation!
    let sceneLocationView = SceneLocationView()
    
    let mapView = MKMapView()
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?
    
    var updateUserLocationTimer: Timer?
    
    ///Whether to show a map view
    ///The initial value is respected
    var showMapView: Bool = true
    
    var centerMapOnUserLocation: Bool = true
    
    ///Whether to display some debugging data
    ///This currently displays the coordinate of the best location estimate
    ///The initial value is respected
    var displayDebugging = false
    
    var infoLabel = UILabel()
    
    var updateInfoLabelTimer: Timer?
    
    var adjustNorthByTappingSidesOfScreen = false
    
    var geoFenceTimer : Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        self.ref = Database.database().reference()
        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        sceneLocationView.addSubview(infoLabel)
        self.setNeedsStatusBarAppearanceUpdate()
        self.mapView.showsUserLocation = true

        // updateInfoLabelTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.updateInfoLabel), userInfo: nil, repeats: true)
        
        //Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
        //        sceneLocationView.orientToTrueNorth = false
        
        //        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.showAxesNode = true
        sceneLocationView.locationDelegate = self
        sceneLocationView.locationEstimateMethod = .mostRelevantEstimate
        sceneLocationView.orientToTrueNorth = true
        
        if displayDebugging {
            sceneLocationView.showFeaturePoints = true
        }
        
        view.addSubview(sceneLocationView)
        
        if showMapView {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.alpha = 1.0
            view.addSubview(mapView)
            
            updateUserLocationTimer = Timer.scheduledTimer( timeInterval: 0.4,target: self,selector: #selector(ViewController.updateUserLocation),userInfo: nil,repeats: true)
        }
        
        self.getMyPins()
        SatoriWrapper.shared().satoriInit { (pdu) in
            if let msg = pdu {
                if let boody = msg.body["messages"] as? [Any], let bdy = boody[0] as? [AnyHashable: AnyObject] {
                    if let lat = bdy["latitude"] as? Double {
                        if let long = bdy["longitude"] as? Double {
                            let annotation = BountyAnnotation(objName: bdy["name"] as! String, phoneNumber: bdy["phone"] as! String)
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            self.mapView.addAnnotation(annotation)
                            print("RECEIVED SATORI")
                        }
                    }
                }
            }
        }
        geoFenceTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(ViewController.iterateThroughAnn), userInfo: nil, repeats: true)
        self.mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ViewController.addAnn(_:))))
    }

    func addAnn(_ gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: self.mapView)
        let newCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
        let annotation = MyAnnotation(loc: CLLocation(coordinate: newCoordinates, altitude: 0.0), pinID: self.ref.childByAutoId().key)
        self.setPinToLocation(location: CLLocation(coordinate: annotation.coordinate, altitude: 0.0), itemName: "Pin_\(annotation.id)", id: annotation.id)
        self.mapView.addAnnotation(annotation)
        self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: LocationNode(location: CLLocation(coordinate: annotation.coordinate, altitude: 0.0)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //DDLogDebug("run")
        sceneLocationView.run()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
    }

    func segueToBounty(){
        self.performSegue(withIdentifier: "bounty", sender: self)
    }

    func deletePin(){
        self.mapView.removeAnnotation(self.currLoc)
        ref.child("Users").child(userID).child("GeoLocations").child(selectedID).removeValue()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? BountyView {
            dest.loc = self.currLoc
            dest.id = selectedID
            KLCPopup.dismissAllPopups()
        }
        
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //DDLogDebug("pause")
        // Pause the view's session
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = CGRect(
            x: 0,
            y: 0,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 2)
        
        infoLabel.frame = CGRect(x: 6, y: 0, width: self.view.frame.size.width - 12, height: 14 * 4)
        
        if showMapView {
            infoLabel.frame.origin.y = (self.view.frame.size.height / 2) - infoLabel.frame.size.height
        } else {
            infoLabel.frame.origin.y = self.view.frame.size.height - infoLabel.frame.size.height
        }
        
        mapView.frame = CGRect(
            x: 0,
            y:  self.view.frame.size.height / 2,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 2)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc func updateUserLocation() {
        if let currentLocation = sceneLocationView.currentLocation() {
            DispatchQueue.main.async {
                
                if let bestEstimate = self.sceneLocationView.bestLocationEstimate(),
                    let position = self.sceneLocationView.currentScenePosition() {
                    //DDLogDebug("")
                    //DDLogDebug("Fetch current location")
                    //DDLogDebug("best location estimate, position: \(bestEstimate.position), location: \(bestEstimate.location.coordinate), accuracy: \(bestEstimate.location.horizontalAccuracy), date: \(bestEstimate.location.timestamp)")
                    //DDLogDebug("current position: \(position)")
                    
                    _ = bestEstimate.translatedLocation(to: position)
                    
                    //DDLogDebug("translation: \(translation)")
                    //DDLogDebug("translated location: \(currentLocation)")
                    //DDLogDebug("")
                }
                
                if self.userAnnotation == nil {
                    self.userAnnotation = MKPointAnnotation()
                    //self.mapView.addAnnotation(self.userAnnotation!)
                }
                
                self.userAnnotation?.coordinate = currentLocation.coordinate

                if self.centerMapOnUserLocation {
                    UIView.animate(withDuration: 0.45, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                        self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
                    }, completion: {
                        _ in
                        self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                    })
                }
                
                if self.displayDebugging {
                    let bestLocationEstimate = self.sceneLocationView.bestLocationEstimate()
                    
                    if bestLocationEstimate != nil {
                        if self.locationEstimateAnnotation == nil {
                            self.locationEstimateAnnotation = MKPointAnnotation()
                        self.mapView.addAnnotation(self.locationEstimateAnnotation!)
                        }
                        
                        self.locationEstimateAnnotation!.coordinate = bestLocationEstimate!.location.coordinate
                    } else {
                        if self.locationEstimateAnnotation != nil {
                            self.mapView.removeAnnotation(self.locationEstimateAnnotation!)
                            self.locationEstimateAnnotation = nil
                        }
                    }
                }
            }
        }
    }
    
    @objc func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition() {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let heading = sceneLocationView.locationManager.heading,
            let accuracy = sceneLocationView.locationManager.headingAccuracy {
            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            if touch.view != nil {
                if (mapView == touch.view! ||
                    mapView.recursiveSubviews().contains(touch.view!)) {
                    centerMapOnUserLocation = false
                } else if sceneLocationView == touch.view! {
                    
                    let location = touch.location(in: self.sceneLocationView)
                    
                    if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                        print("left side of the screen")
                        sceneLocationView.moveSceneHeadingAntiClockwise()
                    } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                        print("right side of the screen")
                        sceneLocationView.moveSceneHeadingClockwise()
                    } else {
                        let image = UIImage(named: "pin")!
                        let annotationNode = LocationAnnotationNode(location: nil, image: image)
                        annotationNode.scaleRelativeToDistance = true
                        sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
                        let key = ref.childByAutoId().key
                        let ann = MyAnnotation(loc: CLLocation(coordinate: annotationNode.location.coordinate, altitude: 0.0), pinID: key)
                        let cloc = CLLocation(coordinate: annotationNode.location.coordinate, altitude: annotationNode.location.altitude)
                        self.mapView.addAnnotation(ann)
                        let randN = arc4random_uniform(101)
                        self.setPinToLocation(location: cloc, itemName: "Pin_\(randN)", id: key)
                    }
                }
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let ann = view.annotation as? BountyAnnotation {
            let view: BountyPopup = BountyPopup.instanceFromNib() as! BountyPopup
            view.parentViewController = self
            popup = KLCPopup(contentView: view, showType: KLCPopupShowType.bounceIn, dismissType: KLCPopupDismissType.fadeOut, maskType: KLCPopupMaskType.dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
            popup.show()
        }
        if let ann = view.annotation as? MyAnnotation {
            self.currLoc = ann
            self.selectedID = ann.id
            let view: MultSelectView = MultSelectView.instanceFromNib() as! MultSelectView
            view.parentViewController = self
            popup = KLCPopup(contentView: view, showType: KLCPopupShowType.bounceIn, dismissType: KLCPopupDismissType.fadeOut, maskType: KLCPopupMaskType.dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
            popup.show()
        }
        mapView.deselectAnnotation(view.annotation, animated: false)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if let pointAnnotation = annotation as? MKPointAnnotation {
            let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            
            if pointAnnotation == self.userAnnotation {
                marker.displayPriority = .required
                marker.glyphImage = UIImage(named: "user")
                marker.markerTintColor = UIColor.black
            } else {
                marker.displayPriority = .required
                //marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
                //marker.glyphImage = UIImage(named: "pin")
            }
            
            if pointAnnotation is BountyAnnotation {
                marker.markerTintColor = UIColor.blue
            }
            
            return marker
        }
        
        return nil
    }
    
    func iterateThroughAnn() {
        for annotation in self.mapView.annotations {
            if(!(annotation is MKUserLocation)) {
                if let ann = annotation as? MyAnnotation {
                    print(userDistance(from: (ann))!)
                    if(userDistance(from: (ann))! > 3.0) {
                        if(geoFenceTimer != nil) {
                            self.geoFenceTimer.invalidate()
                            self.geoFenceTimer = nil
                        }
                        let id = ((annotation as! MyAnnotation).id)
                        if(!(usedValues.contains(id!))) {
                            let alertController = UIAlertController(title: "Don't forget Your Item!", message: "Your geo-pin, \(id!), is still on the map!", preferredStyle: .alert)
                            let action = UIAlertAction(title: "OK", style: .default, handler: {
                                action in
                                self.geoFenceTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(ViewController.iterateThroughAnn), userInfo: nil, repeats: true)
                            })
                            alertController.addAction(action)
                            self.present(alertController, animated: true, completion: nil)
                            usedValues.append(id!)
                        }
                    }
                }
            }
        }
    }
    
    func userDistance(from point: MyAnnotation) -> Double? {
        guard let userLocation = self.mapView.userLocation.location else {
            return nil // User location unknown!
        }
        let pointLocation = CLLocation(
            latitude:  point.coordinate.latitude,
            longitude: point.coordinate.longitude
        )
        return userLocation.distance(from: pointLocation)
    }
    
    //MARK: SceneLocationViewDelegate
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        // DDLogDebug("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        // DDLogDebug("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        
    }
    
    func getMyPins(){
        ref.child("Users").child(userID).child("GeoLocations").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            self.regPins  = []
            self.regPins = snapshot.children.map{ childObj in
                let child = childObj as! DataSnapshot
                let latitude = child.childSnapshot(forPath: "latitude").value as! Double
                let longitude = child.childSnapshot(forPath: "longitude").value as! Double
                let altitude = child.childSnapshot(forPath: "altitude").value as! Double
                let uid = child.childSnapshot(forPath: "id").value as! String

                let type = child.childSnapshot(forPath: "type").value as! String
                
                if(type == "Regular"){

                    let location =  CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: altitude)
                    return MapPoint(loc: location, pinID: uid)
                }
                else{
                    let location =  CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: altitude)
                    return MapPoint(loc: location, pinID: uid)
                }
                
            }
            for rpin in self.regPins {
                let ann = MyAnnotation(loc: rpin.location, pinID: rpin.id)
                self.mapView.addAnnotation(ann)
                let image = UIImage(named: "pin")!
                let annotationNode = LocationAnnotationNode(location: rpin.location, image: image)
                annotationNode.scaleRelativeToDistance = true
                DispatchQueue.main.async {
                    self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
                }
            }
            
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func setPinToLocation(location: CLLocation, itemName: String, id: String){
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let altitude = location.altitude
        
        let type = "Regular"
        let uid = id
        ref.child("Users").child(userID).child("GeoLocations").child(uid).child("latitude").setValue(latitude)
        ref.child("Users").child(userID).child("GeoLocations").child(uid).child("longitude").setValue(longitude)
        ref.child("Users").child(userID).child("GeoLocations").child(uid).child("altitude").setValue(altitude)
        ref.child("Users").child(userID).child("GeoLocations").child(uid).child("type").setValue(type)
        ref.child("Users").child(userID).child("GeoLocations").child(uid).child("itemName").setValue(itemName)
        ref.child("Users").child(userID).child("GeoLocations").child(uid).child("id").setValue(uid)
        //ref.child("Users").child(userID).child("GeoLocations").child(uid).child("itemDescription").setValue(type)
        
    }
}

extension DispatchQueue {
    func asyncAfter(timeInterval: TimeInterval, execute: @escaping () -> Void) {
        self.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: execute)
    }
}

extension UIView {
    func recursiveSubviews() -> [UIView] {
        var recursiveSubviews = self.subviews
        
        for subview in subviews {
            recursiveSubviews.append(contentsOf: subview.recursiveSubviews())
        }
        
        return recursiveSubviews
    }
}

class BountyAnnotation: MKPointAnnotation {
    var nameOfObj : String?
    var phoneNumber : String?

    override init() {
        super.init()
    }
    init(objName: String, phoneNumber: String) {
        super.init()
        self.nameOfObj = objName
        self.phoneNumber = phoneNumber
    }
}


