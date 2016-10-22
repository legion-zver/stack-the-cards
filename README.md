# Stack The Cards (iOS / Swift 3.0)

![example](/images/example.png)

Popular stack of cards for ITS.

Completely free library.

![example-gif](/images/example.gif)

## Usage

Copy to you project files:

AGFloatCard.swift

AGFloatCardStack.swift

```swift
import UIKit

class ViewController: UIViewController, AGFloatCardStackData {

    private var stackCard: AGFloatCardStack? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create stack
        stackCard = AGFloatCardStack(toView: self.view, _delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (stackCard?.getCountCards())! < 1 {
            requestNewCards() // <- this firs request cards (for normal size screen)
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
```

## For change like / dislike image:

```swift
AGFloatCard.likeImageName = "YOU_NAME_IMAGE_FOR_LIKE"
AGFloatCard.dislikeImageName = "YOU_NAME_IMAGE_FOR_DISLIKE"
```
