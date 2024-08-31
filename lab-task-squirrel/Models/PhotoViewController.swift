//
//  PhotoViewController.swift
//  lab-task-squirrel
//
//  Created by Jennifer Biggs on 8/31/24.
//

import Foundation
import UIKit

class PhotoViewController: UIViewController{
    
    @IBOutlet weak var photoView: UIImageView!

    var task: Task!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        photoView.image = task.image
    }
}
