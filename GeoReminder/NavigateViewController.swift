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


class NavigateViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var itemAnnotation: MyAnnotation!
    let locationManager = CLLocationManager()

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

        let mapCamera = MKMapCamera()
        mapCamera.centerCoordinate = self.mapView.userLocation.coordinate
        mapCamera.pitch = 45
        mapCamera.altitude = 1
        mapCamera.heading = 45
        self.mapView.camera = mapCamera

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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
