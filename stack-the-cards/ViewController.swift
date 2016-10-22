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
    
    override func viewDidAppear(_ animated: Bool) {
        if (stackCard?.getCountCards())! < 1 {
            requestNewCards()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func randomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    // MARK: - Requests
    func requestNewCards() {
        if stackCard != nil {
            for _ in 0...10 {
                _ = stackCard?.createNewСard(nibName: "Card", color: randomColor(), likeInit: true, insertToBegin: false)
            }
            stackCard?.updateStackByNewCards();
        }
    }
    
    // MARK: - Stack Cards
    func didRanCards(stack: AGFloatCardStack) {
        requestNewCards()
    }
    
    func didEmptyStack(stack: AGFloatCardStack) {
        requestNewCards()
    }
    
    func didClickingOnCard(card: AGFloatCard, stack: AGFloatCardStack) {
        // Open detail view controller
    }
    
    func didUpdateContentCard(card: AGFloatCard, stack: AGFloatCardStack) {
        // Show card - update / load image
    }
    
    func didActivityCardReport(card: AGFloatCard, location: AGFloatCardLocation, stack: AGFloatCardStack) {
        // left or right fly card
    }
    
    func didCardGoOffscreenSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation) {
        //
    }
}

