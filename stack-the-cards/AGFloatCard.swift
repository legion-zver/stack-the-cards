//
//  AGFloatCard.swift
//
//  Created by Александр Зверь on 27.01.16.
//  Copyright © 2016 ppApp. All rights reserved.
//

import UIKit

// Позиция карточки
enum AGFloatCardLocation {
    case Unknown
    case TopLeft
    case TopRight
    case BottomLeft
    case BottomRight
}

// Протокол
protocol AGFloatCardDelegate {
    // По карточке кликнули
    func didClickingOnCard(card: AGFloatCard)
    
    // Карточка начинает менять позицию
    func willChangeCardPosition(card: AGFloatCard, offset: CGFloat)
    
    // Карточка начинает возвращаться в исходное положение
    func willReturnCardToCenterSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation)
    // Карточка вернулась в исходное положеие
    func didReturnCardToCenterSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation)
    
    // Карточка начинает уходить за пределы экрана
    func willCardGoOffscreenSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation)
    // Карточка ушла за пределы экрана
    func didCardGoOffscreenSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation)
}

class AGFloatCard: UIView, CAAnimationDelegate {
    // Константы
    private let defSwipeDistance: CGFloat = 90.0
    private let defRotationAngle: CGFloat = 9.0
    private let defDelayAnimation = 0.4
    private let defRasterization  = true
    
    // Для отслеживания перемещения карточки
    private var lastLocation:  CGPoint = CGPoint.zero
    private var startLocation: CGPoint = CGPoint.zero
    private var savePosition:  CGPoint = CGPoint.zero
    private var velocity:      CGPoint = CGPoint.zero
    private var slideFactor:   CGFloat = 0.0
    private var rotation:      CGFloat = 0.0
    
    // Флаг нажатия сверху карточки
    private var topTap:        Bool = false
    private var numTouches:    Int = 0
    
    // Флаг нахождения вне зоны видимости на экране
    private var offscreen:     Bool = false
    func isOffscreen()->Bool   {return self.offscreen}
    
    // Делегат
    var delegate: AGFloatCardDelegate?
    
    static var likeImageName: String = "CardLike"
    static var dislikeImageName: String = "CardDislike"
   
    // Like&Dislike ImageView
    let likeDislikeEnable: Bool
    var likeImgView:       UIImageView?
    var dislikeImgView:    UIImageView?
    
    // Пользовательские данные
    var userData: Any? = nil
    
    // Верстка из nib/xib файла
    func makeupFromNib(nibName name: String) {
        self.autoresizesSubviews = true
        self.translatesAutoresizingMaskIntoConstraints = true
        if let view = UINib(nibName: name, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UIView {            
            view.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            view.bounds = self.bounds
            view.autoresizesSubviews = true
            view.translatesAutoresizingMaskIntoConstraints = true
            self.addSubview(view)
            
            view.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            view.autoresizingMask = [UIViewAutoresizing.flexibleLeftMargin, UIViewAutoresizing.flexibleRightMargin, UIViewAutoresizing.flexibleTopMargin, UIViewAutoresizing.flexibleBottomMargin]
        }        
    }
    
    // Инициализация
    init(nibName name: String, frame cgFrame: CGRect, bkgColor: UIColor, likeInit: Bool = true) {
        likeDislikeEnable = likeInit
        super.init(frame: cgFrame)
        self.initCard()
        self.makeupFromNib(nibName: name)
        if likeImgView != nil {
            self.bringSubview(toFront: likeImgView!)
        }
        if dislikeImgView != nil {
            self.bringSubview(toFront: dislikeImgView!)
        }
        self.backgroundColor = bkgColor
    }
    
    init(frame cgFrame: CGRect, bkgColor: UIColor, likeInit: Bool = true) {
        likeDislikeEnable = likeInit
        
        super.init(frame: cgFrame)
        self.initCard()
        
        self.backgroundColor = bkgColor
    }
    
    override init(frame cgFrame: CGRect) {
        likeDislikeEnable = false
        super.init(frame: cgFrame)
        self.initCard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        likeDislikeEnable = false
        super.init(coder: aDecoder)
        self.initCard()
    }
    
    // Инициализация карточки
    private func initCard()
    {
        backgroundColor     = UIColor.white
        layer.cornerRadius  = 8.0
        
        // Создание тени
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowRadius  = 3.0
        layer.shadowOpacity = 0.3334
        layer.cornerRadius  = 8.0
        
        layer.shadowOffset  = CGSize(width: 0, height: 1)
        layer.shadowPath    = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: layer.frame.width, height: layer.frame.height), cornerRadius: 8.0).cgPath
        
        if(defRasterization)
        {
            layer.shouldRasterize    = true
            layer.rasterizationScale = UIScreen.main.scale
        }
        layer.transform = CATransform3DIdentity
        
        // Отслеживаем перемещение
        let pan = UIPanGestureRecognizer(target: self, action: #selector(AGFloatCard.handlePan(recognizer:)))
        addGestureRecognizer(pan)
        
        // Отслеживаем нажатия
        let tap = UITapGestureRecognizer(target: self, action:#selector(AGFloatCard.handleTap(recognizer:)))
        addGestureRecognizer(tap)
        
        // Инициализация Like&Dislike
        if(likeDislikeEnable){initLikeDislike()}        
    }
    
    private func initLikeDislike()
    {
        var k: CGFloat      = 0.0
        let width: CGFloat  = self.frame.size.width*0.6
        
        likeImgView  = UIImageView(image: UIImage(named: AGFloatCard.likeImageName))
        if(likeImgView != nil)
        {
            likeImgView?.layer.opacity  = 0.0
            
            k = likeImgView!.frame.size.height/likeImgView!.frame.size.width
            if(k.isNaN || k == 0) {
                k = 0.9883
            }
            
            likeImgView!.frame = CGRect(x: (self.frame.size.width-width)*0.5, y: (self.frame.size.height-(width*k))*0.5, width: width, height: width*k)
            
            addSubview(likeImgView!)
        }
        
        dislikeImgView = UIImageView(image: UIImage(named: AGFloatCard.dislikeImageName))
        if(dislikeImgView != nil)
        {
            dislikeImgView?.layer.opacity   = 0.0
            
            k = dislikeImgView!.frame.size.height/dislikeImgView!.frame.size.width
            if(k.isNaN || k == 0){
                k = 0.9883
            }
            
            dislikeImgView!.frame = CGRect(x: (self.frame.size.width-width)*0.5, y: (self.frame.size.height-(width*k))*0.5, width: width, height: width*k)
            
            addSubview(dislikeImgView!)
        }
    }
    
    func resetMove() {
        self.layer.position = self.savePosition
        self.layer.transform = CATransform3DMakeRotation(0.0, 0.0, 0.0, 1.0)
    }
    
    // Взаимодействие с карточкой (перемещение)
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer)
    {
        let location = recognizer.location(in: superview)
        if(recognizer.state == UIGestureRecognizerState.began)
        {
            savePosition  = layer.position
            startLocation = location
            topTap = (recognizer.location(in: self).y <= savePosition.y)
        }
        else if(recognizer.state == UIGestureRecognizerState.changed)
        {
            if(numTouches != recognizer.numberOfTouches)
            {
                lastLocation = location
                numTouches = recognizer.numberOfTouches
            }
            
            layer.position.x -= (lastLocation.x-location.x)
            layer.position.y -= (lastLocation.y-location.y)
            
            self.rotation = (defRotationAngle)*(-layer.position.x/savePosition.x+1)
            if(self.rotation>0.0){self.rotation = min(self.rotation, self.defRotationAngle)}
            else{self.rotation = max(self.rotation, -self.defRotationAngle)}
            if(self.topTap){self.self.rotation = -self.rotation;}
            
            self.layer.transform = CATransform3DMakeRotation(self.rotation*CGFloat(M_PI)/180.0, 0.0, 0.0, 1.0)
            lastLocation = location
            
            // Рассчитываем дельту
            var delta:Float = Float(savePosition.x-layer.position.x)
            if(delta<0)
            {
                delta = (-delta/Float(defSwipeDistance) > 1 ? 1 : -delta/Float(defSwipeDistance))
                
                // Показываем LIKE и скрываем DISLIKE
                if(likeImgView != nil){likeImgView?.layer.opacity = 0.85*delta}
                if(dislikeImgView != nil){dislikeImgView?.layer.opacity = 0.0}
            }
            else
            {
                delta = (delta/Float(defSwipeDistance) > 1 ? 1 : delta/Float(defSwipeDistance))
                
                // Показываем DISLIKE и скрываем LIKE
                if(likeImgView != nil){likeImgView?.layer.opacity = 0.0}
                if(dislikeImgView != nil){dislikeImgView?.layer.opacity = 0.85*delta}
            }
            if(self.delegate != nil) {
                self.delegate?.willChangeCardPosition(card: self, offset: CGFloat(delta))
            }
        }
        else if(recognizer.state == UIGestureRecognizerState.ended)
        {
            self.numTouches = 0
            //------------------
            self.velocity = recognizer.velocity(in: superview)
            self.slideFactor = 0.0025 * (sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))/200.0)
            //------------------
            self.playAnimationFly(toPosition: CGPoint(x: layer.position.x+(self.velocity.x*self.slideFactor),
                y: layer.position.y+(self.velocity.y*self.slideFactor)), duration: Double(self.slideFactor)*1.85);
            
        }
        lastLocation = location
    }
    
    // MARK: Animation
    private func playAnimationFly(toPosition:CGPoint, duration: CFTimeInterval) {
        let fly:CABasicAnimation = CABasicAnimation(keyPath: "position")
        fly.fromValue = NSValue(cgPoint: self.layer.position)
        fly.toValue = NSValue(cgPoint: toPosition)
        fly.duration = duration
        fly.delegate = self
        
        fly.setValue("fly", forKey: "id")
        
        // Запускаем анимацию
        self.layer.removeAllAnimations()
        self.layer.add(fly, forKey: "fly")
        
        self.layer.position = toPosition
    }
    
    private func playAnimationToCenter(duration:CFTimeInterval) {
        let group: CAAnimationGroup = CAAnimationGroup()
        group.duration = duration
        
        let rotate:CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = self.rotation*CGFloat(M_PI)/180.0
        rotate.toValue = 0.0
        rotate.duration = duration
        
        let fly:CABasicAnimation = CABasicAnimation(keyPath: "position")
        fly.fromValue = NSValue(cgPoint: self.layer.position)
        fly.toValue = NSValue(cgPoint: self.savePosition)
        fly.duration = duration
        
        group.animations = [rotate, fly]
        group.delegate = self
        
        group.setValue("center", forKey: "id")
        
        // Запускаем анимацию
        self.layer.add(group, forKey: "center")
        
        self.layer.position = self.savePosition
        self.layer.transform = CATransform3DMakeRotation(0, 0, 0, 1.0)
        
        if(self.likeImgView != nil) {
            if(Double((self.likeImgView?.layer.opacity)!) > 0.0){
                let alphaLike:CABasicAnimation = CABasicAnimation(keyPath: "opacity")
                alphaLike.fromValue = self.likeImgView?.layer.opacity
                alphaLike.toValue = 0.0
                alphaLike.duration = duration
                self.likeImgView?.layer.add(alphaLike, forKey: "likeOpacityReset")
                self.likeImgView?.layer.opacity = 0.0
            }
        }
        
        if(self.dislikeImgView != nil) {
            if(Double((self.dislikeImgView?.layer.opacity)!) > 0.0) {
                let alphaDisLike:CABasicAnimation = CABasicAnimation(keyPath: "opacity")
                alphaDisLike.fromValue = self.dislikeImgView?.layer.opacity
                alphaDisLike.toValue = 0.0
                alphaDisLike.duration = duration
                self.dislikeImgView?.layer.add(alphaDisLike, forKey: "dislikeOpacityReset")
                self.dislikeImgView?.layer.opacity = 0.0
            }
        }
    }
    
    private func playAnimationToEnd(duration:CFTimeInterval)
    {
        let end:CABasicAnimation = CABasicAnimation(keyPath: "position")
        
        if(self.superview != nil) {
            let toPosition = CGPoint(x:((self.savePosition.x-self.layer.position.x) > 0 ? -(self.superview?.frame.origin.x)!-self.bounds.size.width : (self.superview?.frame.size.width)!+self.bounds.size.width), y: self.layer.position.y+(self.velocity.y*self.slideFactor))
            
            end.toValue = NSValue(cgPoint: toPosition)
        
        } else {
            end.toValue = NSValue(cgPoint: self.layer.position)
        }
        end.fromValue = NSValue(cgPoint: self.layer.position)
        end.duration = duration
        end.delegate = self
        
        end.setValue("end", forKey: "id")
        
        // Запускаем анимацию
        self.layer.add(end, forKey: "end")
        
        self.layer.position = (end.toValue as! NSValue).cgPointValue
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool)
    {
        if let key = anim.value(forKey: "id") as? String {
            if(key == "fly")
            {
                if(CGFloat(labs(Int(self.savePosition.x-self.layer.position.x))) < self.defSwipeDistance)
                {
                    if(self.delegate != nil) {
                        self.delegate?.willReturnCardToCenterSubview(card: self, fromLocation: getCardLocation(point: self.layer.position))
                    }
                    self.playAnimationToCenter(duration: self.defDelayAnimation*0.5)
                    
                } else {
                    if(self.delegate != nil) {
                        self.delegate?.willCardGoOffscreenSubview(card: self, fromLocation: getCardLocation(point: self.layer.position))
                    }
                    self.playAnimationToEnd(duration: self.defDelayAnimation*0.5)
                }
            } else if(key == "center") {
                if(self.delegate != nil) {
                    self.delegate?.didReturnCardToCenterSubview(card: self, fromLocation: getCardLocation(point: self.layer.position))
                }
            } else if(key == "end"){
                if(self.delegate != nil) {
                    self.delegate?.didCardGoOffscreenSubview(card: self, fromLocation: getCardLocation(point: self.layer.position))
                }
            }
        }
    }
    
    // Взаимодействие с карточкой (нажатие)
    @IBAction func handleTap(recognizer:UITapGestureRecognizer)
    {
        if(self.delegate != nil) {
            self.delegate?.didClickingOnCard(card: self)
        }
    }
    
    // Сброс прозрачности элементов Like&Dislike до 0.0
    func resetLikeAndDislikeOpacity()
    {
        if(likeImgView != nil){likeImgView?.alpha = 0.0}
        if(dislikeImgView != nil){dislikeImgView?.alpha = 0.0}
    }
   
    // Установка трансформаций (для стека и его красивых анимаций)
    func setTransforms(scale: CGFloat, i: Int, offset: CGFloat, listOffset: CGFloat, resetOpacity: Bool, a: CGFloat)
    {
        // Установка транформации вращения и масштаба
        transform = CGAffineTransform(rotationAngle: 0)
        layer.transform.m11 = scale
        layer.transform.m22 = scale
        
        if(superview != nil){
            layer.position.y = superview!.center.y+(CGFloat(i)*listOffset)+(listOffset*offset)+(layer.frame.size.height*(CGFloat(i)+offset)*listOffset*0.002)
        }
        
        if(a>=0.0)
        {self.alpha = a}
        
        if(resetOpacity)
        {resetLikeAndDislikeOpacity()}
    }
    
    // Получение локации по позиции
    func getCardLocation(point:CGPoint)->AGFloatCardLocation
    {
        if((superview) != nil)
        {
            let middleX:CGFloat = (superview?.frame.size.width)!/2;
            let middleY:CGFloat = (superview?.frame.size.height)!/2;
            
            if(point.x<middleX){
                if(point.y<middleY){
                    return AGFloatCardLocation.TopLeft
                }
                return AGFloatCardLocation.BottomLeft
            }
            else
            {
                if(point.y<middleY){
                    return AGFloatCardLocation.TopRight
                }
                return AGFloatCardLocation.BottomRight
            }
        }
        return AGFloatCardLocation.Unknown
    }    
    
    //MARK: DEINIT
    deinit {
        if userData != nil {
            userData = nil
        }
    }
}
