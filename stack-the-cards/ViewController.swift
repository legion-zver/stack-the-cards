//
//  ViewController.swift
//  stack-the-cards
//
//  Created by Александр Зверь on 22.10.16.
//  Copyright © 2016 ALEXANDER GARIN. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AGFloatCardStackData {

    private var stackCard: AGFloatCardStack? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Создаем стек для карточек
        stackCard = AGFloatCardStack(toView: self.view, _delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

