//
//  NavVC.swift
//  GeoReminder
//
//  Created by Patrick Li on 7/30/17.
//  Copyright © 2017 Dhruv Shah. All rights reserved.
//

import UIKit

class NavVC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.barStyle = UIBarStyle.default
        self.navigationBar.tintColor = UIColor.white

        // Do any additional setup after loading the view.
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
