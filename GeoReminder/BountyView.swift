//
//  BountyView.swift
//  GeoReminder
//
//  Created by Patrick Li on 7/30/17.
//  Copyright © 2017 Dhruv Shah. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase




class BountyView: UIViewController, UITextFieldDelegate {



    var id: String!
    var loc: MyAnnotation!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        phoneField.keyboardType = UIKeyboardType.numberPad
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirmClicked(_ sender: Any) {
       // ref.child("Users").child("jdinlkj392djf").child("GeoLocations").child(id).removeValue()
        SatoriWrapper.shared().publishLocation(["latitude": self.loc.coordinate.latitude, "longitude": self.loc.coordinate.longitude, "name": nameField.text!, "phone": phoneField.text!])
        self.navigationController?.popViewController(animated: true)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let prospectiveText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        return string.characters.count == 0 || CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: prospectiveText))

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
