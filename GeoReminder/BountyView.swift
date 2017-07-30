//
//  BountyView.swift
//  GeoReminder
//
//  Created by Patrick Li on 7/30/17.
//  Copyright © 2017 Dhruv Shah. All rights reserved.
//

import UIKit



class BountyView: UIViewController, UITextFieldDelegate {



    var id: String!
    var loc: MyAnnotation!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirmClicked(_ sender: Any) {
        
        SatoriWrapper.shared().publishLocation(["latitude": self.loc.coordinate.latitude, "longitude": self.loc.coordinate.longitude, "name": nameField.text!, "phone": phoneField.text!])
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
