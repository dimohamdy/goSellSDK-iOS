//
//  OTPDismissalInteractionController.swift
//  goSellSDK
//
//  Copyright © 2018 Tap Payments. All rights reserved.
//

import struct   CoreGraphics.CGBase.CGFloat
import func     TapAdditionsKit.clamp
import class    UIKit.UIPanGestureRecognizer.UIPanGestureRecognizer
import class    UIKit.UIResponder.UIResponder

internal final class OTPDismissalInteractionController: BaseInteractionController {
    
    // MARK: - Internal -
    // MARK: Methods
    
    internal init(viewController: OTPViewController) {
        
        self.viewController = viewController
        super.init()
        
        self.setupGestureRecognizer()
    }
    
    internal override func callDismissOrPop(_ animated: Bool) {
        
        let presentingController = self.viewController.presentingViewController
        
        let responder = self.viewController.view.firstResponder
        responder?.resignFirstResponder()
        
        self.firstResponderOnMomentOfDismissal = responder
        
        self.viewController.dismiss(animated: animated) {
            
            guard presentingController?.presentedViewController == nil else { return }
            
            presentingController?.dismiss(animated: false) {
                
                OTPViewController.destroyInstance()
            }
        }
    }
    
    internal override func cancel() {
        
        super.cancel()
        
        self.viewController.presentationAnimationAnimatingConstraint?.constant = 0.0
        self.firstResponderOnMomentOfDismissal?.becomeFirstResponder()
    }
    
    // MARK: - Private -
    
    private struct Constants {
        
        fileprivate static let translationPercentageToFinishTransition: CGFloat = 0.4
        
        @available(*, unavailable) private init() {}
    }
    
    // MARK: Properties
    
    private var shouldCompleteTransitionOnGestureFinish: Bool = false
    private unowned let viewController: OTPViewController
    
    private weak var firstResponderOnMomentOfDismissal: UIResponder?
    
    // MARK: Methods
    
    private func setupGestureRecognizer() {
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(panDetected(_:)))
        
        self.viewController.addInteractiveDismissalRecognizer(recognizer)
    }
    
    @objc private func panDetected(_ recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
            
        case .began:
            
            self.begin()
            self.update(0.0)
            
        case .changed:
            
            let window = recognizer.view?.window
            
            let translation = recognizer.translation(in: window).y
            let velocity = recognizer.velocity(in: window).y
            let maxTranslation = self.viewController.view.bounds.size.height
            let edgeTranslation = maxTranslation * Constants.translationPercentageToFinishTransition
            let animationProgress = clamp(value: translation / maxTranslation, low: 0.0, high: 1.0)
            let translationIfReleased = translation + velocity * self.duration
            
            self.shouldCompleteTransitionOnGestureFinish = translationIfReleased >= edgeTranslation
            self.update(animationProgress)
            
        case .cancelled:
            
            self.cancel()
            
        case .ended:
            
            if self.shouldCompleteTransitionOnGestureFinish {
                
                self.finish()
            }
            else {
                
                self.cancel()
            }
            
        default:
            
            break
        }
    }
}