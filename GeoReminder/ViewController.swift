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

class ViewController: UIViewController {

    //map
    var myPins = [CLLocation]()
    var userID = "jdinlkj392djf"

    //firebase
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()

        //firebase
        ref = Database.database().reference()
        ref.child("Users").child(userID).child("GeoLocations").childByAutoId().setValue("d")

    }

    func setPinToLocation(location: CLLocation){
        var locationX = 1
        var locationY = 1
        ref.child("Users").child(userID).child("GeoLocations").childByAutoId()//.child("positionX").setValue(locationX)
        ref.child("Users").child(userID).child("GeoLocations").childByAutoId()//.child("positionY").setValue(locationX)

    }

    func getMyPins(){

    }

    func getNearbyBounties(){

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
















}

