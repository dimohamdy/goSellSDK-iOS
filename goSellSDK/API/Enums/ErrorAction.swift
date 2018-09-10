//
//  ErrorAction.swift
//  goSellSDK
//
//  Copyright © 2018 Tap Payments. All rights reserved.
//

internal struct ErrorAction: OptionSet {
    
    // MARK: - Internal -
    
    internal let rawValue: Int
    
    internal static let retry           = ErrorAction(rawValue: 1     )
    internal static let alert           = ErrorAction(rawValue: 1 << 1)
    internal static let closePayment    = ErrorAction(rawValue: 1 << 2)
}