//
//  AGFloatCardStack.swift
//  ixoxo
//
//  Created by Александр Зверь on 27.01.16.
//  Copyright © 2016 ppApp. All rights reserved.
//

import UIKit

protocol AGFloatCardStackData
{
    func didRanCards(stack: AGFloatCardStack)
    func didEmptyStack(stack: AGFloatCardStack)
    func didClickingOnCard(card: AGFloatCard, stack: AGFloatCardStack)
    func didUpdateContentCard(card: AGFloatCard, stack: AGFloatCardStack)
    func didActivityCardReport(card: AGFloatCard, location: AGFloatCardLocation, stack: AGFloatCardStack)
    func didCardGoOffscreenSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation)
}

class AGFloatCardStack: AGFloatCardDelegate
{
    // Def значения
    let defUnodCardCount:       Int = 4
    let defShowCardCount:       Int = 4
    let defMinCardCountInStack: Int = 18
    let defMargin:          CGFloat = 16
    let defListOffset:      CGFloat = 8
    
    // Делегат данных
    let delegate: AGFloatCardStackData
    
    // Для смещения в сессии
    private var offsetSessionByRequest:     Int = 0
    private var lastOffsetSessionByRequest: Int = 0
    
    // Стек карточек
    var cardStack     = [AGFloatCard]()
    var showCardStack = [AGFloatCard]()
    var undoCardStack = [AGFloatCard]()
    
    // Вьюшка в которую необходимо добавлять карточки
    var superview: UIView? = nil
    
    // Инициализация
    init(toView: UIView, _delegate: AGFloatCardStackData) {
        self.delegate = _delegate
        self.superview = toView;
    }
    
    // Заполнение стека показа
    private func fillShowStack(testCount:Bool = true)
    {
        if(self.superview != nil)
        {
            let count: Int = defShowCardCount - showCardStack.count
            for _ in 0..<count
            {
                if(cardStack.count>0)
                {
                    let card: AGFloatCard = cardStack.removeFirst()
                    self.superview?.addSubview(card)
                    self.superview?.sendSubview(toBack: card)
                    showCardStack.append(card)
                    
                    // Обновляем контент при выводе в стек показа
                    delegate.didUpdateContentCard(card: card, stack: self)
                }
                else
                {break}
            }
            
            // Сброс трансформаций
            resetShowCardsTransforms()
            
            // Разрешаем взаимодействие с первой карточкий
            self.enableFirstShowCard()

            if(testCount == true)
            {
                if(showCardStack.count+cardStack.count < defMinCardCountInStack)
                {
                    if(showCardStack.count+cardStack.count <= 0 && offsetSessionByRequest > 0)
                    {
                        if(lastOffsetSessionByRequest != offsetSessionByRequest || lastOffsetSessionByRequest == 0)
                        {
                            lastOffsetSessionByRequest = offsetSessionByRequest
                            delegate.didEmptyStack(stack: self)
                        }
                    }
                    else
                    { delegate.didRanCards(stack: self) }
                }
            }
        }
    }
    
    // Разрешаем взаимодействие с первой карточкий
    func enableFirstShowCard() {
        if(showCardStack.count>0) {
            let card = showCardStack.first
            if card != nil {
                card?.isUserInteractionEnabled = true
                card?.isMultipleTouchEnabled   = true
            }
        }
    }
    
    // Запрещаем взаимодействие с первой карточкий
    func disableFirstShowCard() {
        if(showCardStack.count>0) {
            let card = showCardStack.first
            if card != nil {
                card?.isUserInteractionEnabled = false
                card?.isMultipleTouchEnabled   = false
            }
        }
    }
    
    func clear() {
        self.cardStack.removeAll()
        for card in self.showCardStack{
            card.removeFromSuperview()
        }
        self.showCardStack.removeAll()
        self.undoCardStack.removeAll()
        //-----------------------------
        self.offsetSessionByRequest = 0
        self.lastOffsetSessionByRequest = 0
    }
    
    func getCountCards()->Int { return showCardStack.count+cardStack.count }
    func getOffsetBySession(last:Bool = false)->Int { return last == true ? self.lastOffsetSessionByRequest : self.offsetSessionByRequest }
    
    func resetOffsetBySession() {
        self.offsetSessionByRequest = 0
        self.lastOffsetSessionByRequest = 0
    }
    
    private func getSuperviewCenterY()->CGFloat {
        if(self.superview != nil) {
            return (self.superview?.frame.size.height)!/2
        }
        return 0
    }
    
    private func getSuperviewCenterX()->CGFloat {
        if(self.superview != nil) {
            return (self.superview?.frame.size.width)!/2
        }
        return 0
    }
    
    // Сброс трансформации у всех карточек в показе
    func resetShowCardsTransforms()
    {
        let centerX = getSuperviewCenterX();
        let centerY = getSuperviewCenterY();
        
        for i in 0..<showCardStack.count
        {
            let card = showCardStack[i];
            let scale = 1.0 - (CGFloat(i)*defListOffset*0.005)
            
            card.resetLikeAndDislikeOpacity()
            card.layer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, scale)            
            
            card.layer.position.y = centerY+(CGFloat(i)*defListOffset)+(card.layer.frame.size.height*(CGFloat(i))*defListOffset*0.002)
            card.layer.position.x = centerX
            
            card.alpha = (i != showCardStack.count-1 || showCardStack.count <= defShowCardCount-1) ? 1.0 : 0.0
        }
    }
    
    // Изменение скрытия и масштаб
    func modificateShowCardsByFirstCardOffset(offset: CGFloat)
    {
        if(showCardStack.count>0)
        {
            let i: Int = showCardStack.count-1
            var scale: CGFloat
            
            let centerX = getSuperviewCenterX();
            let centerY = getSuperviewCenterY();
            
            if(i > 0){
                let lastCard: AGFloatCard = showCardStack.last!
                
                if(showCardStack.count > defShowCardCount-1)
                {lastCard.alpha = offset}
                
                scale = 1.0 - ((CGFloat(i)-offset)*defListOffset*0.005)
                lastCard.layer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, scale)
                
                lastCard.layer.position.y = centerY+(CGFloat(i)*defListOffset)+(defListOffset*(-offset))+(lastCard.layer.frame.size.height*(CGFloat(i)-offset)*defListOffset*CGFloat(0.002))
                
                lastCard.layer.position.x = centerX                
            }
            if(showCardStack.count>1){
                for i in 1..<(showCardStack.count-1){
                    let card = showCardStack[i]
                    
                    scale = 1.0 - ((CGFloat(i)-offset)*defListOffset*0.005)
                    card.layer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, scale)
                    
                    card.layer.position.y = centerY+(CGFloat(i)*defListOffset)+(defListOffset*(-offset))+(card.layer.frame.size.height*(CGFloat(i)-offset)*defListOffset*CGFloat(0.002))
                    
                    card.layer.position.x = centerX
                }
            }
        }
    }
    //-----------------------------------------
    // Операция отмены
    //-----------------------------------------
    func undo() {
        if self.undoCardStack.count > 0 {
            let card = self.undoCardStack.removeFirst()
            if self.superview != nil {
                // Убираем взаимодействие с первой картой в стеке показа
                self.disableFirstShowCard()
                // Кладем карточку поверх карт просмотра
                self.superview?.addSubview(card)
                self.superview?.bringSubview(toFront: card)
                self.showCardStack.insert(card, at: 0)
                // Складываем последнюю карточку из показа в стек если нужно
                if self.showCardStack.count > self.defShowCardCount {
                    let last = self.showCardStack.removeLast()
                    last.removeFromSuperview()
                    self.cardStack.insert(last, at: 0)
                }
                // Сброс трансформаций
                resetShowCardsTransforms()                
                // Разрешаем взаимодействие с первой карточкий
                self.enableFirstShowCard()
            }
        }
    }
    //-----------------------------------------
    // События на карточках
    //-----------------------------------------
    // Нажатие карточки
    func didClickingOnCard(card: AGFloatCard){
        delegate.didClickingOnCard(card: card, stack: self)
    }
    
    // Изменение позиции карточки
    func willChangeCardPosition(card: AGFloatCard, offset: CGFloat){
        // Производим анимацию проявления и масштабирования карточек
        modificateShowCardsByFirstCardOffset(offset: offset)
    }
    
    // Начало возврата в центр
    func willReturnCardToCenterSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation){
        UIView.animate(withDuration: 0.2) { () -> Void in
            self.modificateShowCardsByFirstCardOffset(offset: 0.0)
        }
    }
    
    // Окончательный возврат в центр
    func didReturnCardToCenterSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation) {
        
    }
    
    // Начало скрытия за пределы экрана
    func willCardGoOffscreenSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation) {
        self.modificateShowCardsByFirstCardOffset(offset: 1.0)
        delegate.didActivityCardReport(card: card, location: fromLocation, stack: self)
        let index: Int? = showCardStack.index(of: card)
        if(index != nil && index! >= 0 && index! < showCardStack.count)
        { showCardStack.remove(at: index!) }
        self.fillShowStack()
    }
    // Конец скрытия за пределами экрана
    func didCardGoOffscreenSubview(card: AGFloatCard, fromLocation: AGFloatCardLocation) {
        card.removeFromSuperview()
        // Если есть UndoStack то кладем в него карточки
        if self.defUnodCardCount > 0 {
            self.undoCardStack.insert(card, at: 0)
            if self.undoCardStack.count > self.defUnodCardCount {
                self.undoCardStack.removeLast()
            }
        }
        // Вызов делегата
        self.delegate.didCardGoOffscreenSubview(card: card, fromLocation: fromLocation)
    }
    
    //MARK: Заполнение стека
    func createNewСard(nibName: String = "", color: UIColor, likeInit:Bool = true, insertToBegin:Bool = false)->(AGFloatCard) {
        let card: AGFloatCard
        
        // Проверка на nib/xib
        if(nibName.characters.count > 0) {
            card = AGFloatCard(nibName: nibName, frame: CGRect(x: defMargin, y: defMargin, width: (self.superview?.frame.width)!-defMargin*2, height: (self.superview?.frame.height)!-defMargin*2), bkgColor: color, likeInit: likeInit)
        } else {
            card = AGFloatCard(frame: CGRect(x: defMargin, y: defMargin, width: (self.superview?.frame.width)!-defMargin*2, height: (self.superview?.frame.height)!-defMargin*2), bkgColor: color, likeInit: likeInit)
        }
        card.delegate = self
        card.isUserInteractionEnabled = false
        card.isMultipleTouchEnabled   = false
        if insertToBegin {
            cardStack.insert(card, at: 0)
        } else {
            cardStack.append(card)
        }
        offsetSessionByRequest += 1
        return card
    }
    
    // Обновление стека
    func updateStackByNewCards() {
        self.fillShowStack(testCount: false)
    }
}
