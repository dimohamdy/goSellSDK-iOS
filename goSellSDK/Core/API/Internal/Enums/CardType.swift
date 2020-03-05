//
//  AcceptedCardType.swift
//  goSellSDK
//
//  Created by Osama Rabie on 19/02/2020.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
/// Card Types the merchanty will use to define what types of cards he wants his clients to use
@objc public class CardType:NSObject {
	
    
    @objc var cardType:cardTypes = .All
    
      init(cardType:String) {
        if cardType.lowercased() == "credit"
        {
            self.cardType = .Credit
        }else if cardType.lowercased() == "debit"
        {
            self.cardType = .Debit
        }else
        {
            self.cardType = .All
        }
    }
    
    @objc public init(cardType:cardTypes) {
           self.cardType = cardType
       }
    
    override public func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CardType {
            return self.cardType == other.cardType
        } else {
            return false
        }
    }
}



