//
//  NavigateViewController.swift
//  GeoReminder
//
//  Created by Patrick Li on 7/30/17.
//  Copyright © 2017 Dhruv Shah. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import KLCPopup


class NavigateViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var itemAnnotation: MyAnnotation!
    let locationManager = CLLocationManager()
    var mapCamera: MKMapCamera!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        locationManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.requestLocation()
        }

        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)

        self.mapCamera = MKMapCamera()
        mapCamera.centerCoordinate = self.mapView.centerCoordinate
        mapCamera.pitch = 15
        mapCamera.altitude = 15
        mapCamera.heading = 45
        self.mapView.setCamera(self.mapCamera, animated: false)
        self.mapView.isRotateEnabled = true
        mapView.showsBuildings = true
        let request = MKDirectionsRequest()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: self.itemAnnotation.coordinate))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.mapView.userLocation.coordinate))
        request.requestsAlternateRoutes = false
        request.transportType = .walking

        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }

            if let route = unwrappedResponse.routes[0] as? MKRoute {
                self.mapView.add(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
        self.mapView.showsUserLocation = true
        self.mapView.addAnnotation(itemAnnotation)
        self.mapView.mapType = MKMapType.hybridFlyover

        KLCPopup.dismissAllPopups()
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.mapCamera = MKMapCamera()
        self.mapCamera.heading = (newHeading.trueHeading + 90.0).truncatingRemainder(dividingBy: 360)
        self.mapCamera.altitude = 15
        self.mapView.setCamera(self.mapCamera, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
