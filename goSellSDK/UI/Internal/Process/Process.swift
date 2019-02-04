//
//  Process.swift
//  goSellSDK
//
//  Copyright © 2019 Tap Payments. All rights reserved.
//

import struct	TapAdditionsKit.TypeAlias
import class	UIKit.UIImage.UIImage

internal final class Process {
	
	// MARK: - Internal -
	// MARK: Properties
	
	internal private(set) var transactionMode:	TransactionMode	= .default
	internal private(set) var appearance:		AppearanceMode	= .fullscreen
	
	internal private(set) var externalSession: SessionProtocol?
	
	internal var wrappedImplementation: Wrapped {
		
		if let existing = self.wrapped {
			
			if let _: Process.Implementation<PaymentClass> = existing.implementation(), (self.transactionMode == .purchase || self.transactionMode == .authorizeCapture) {
				
				return existing
			}
			else if let _: Process.Implementation<CardSavingClass> = existing.implementation(), self.transactionMode == .cardSaving {
				
				return existing
			}
		}
		
		switch self.transactionMode {
			
		case .purchase, .authorizeCapture:
			
			let impl = Implementation<PaymentClass>.with(process: self, mode: PaymentClass.self)
			let w = Wrapped(impl)
			
			self.wrapped = w
			
			return w
			
		case .cardSaving:
			
			let impl = Implementation<CardSavingClass>.with(process: self, mode: CardSavingClass.self)
			let w = Wrapped(impl)
			
			self.wrapped = w
			
			return w
		}
	}
	
	// MARK: Methods
	
	internal static func paymentClosed() {
		
		KnownStaticallyDestroyableTypes.destroyAllInstances()
	}
	
	@discardableResult internal func start(_ session: SessionProtocol) -> Bool {
		
		self.transactionMode	= session.dataSource?.mode ?? .default
		self.appearance			= self.obtainAppearanceMode(from: session)
		
		let result = self.dataManagerInterface.loadPaymentOptions(for: session)
		
		if result {
			
			self.externalSession = session
			self.customizeAppearance(for: session)
		}
		
		return result
	}
	
	// MARK: - Private -
	// MARK: Properties
	
	private static var storage: Process?
	
	private var wrapped: Wrapped?
	
	// MARK: Methods
	
	private init() {
		
		KnownStaticallyDestroyableTypes.add(Process.self)
	}
	
	private func obtainAppearanceMode(from session: SessionProtocol) -> AppearanceMode {
		
		let publicAppearance = session.appearance?.appearanceMode?(for: session) ?? .default
		let transactionMode = session.dataSource?.mode ?? .default
		
		let result = AppearanceMode(publicAppearance: publicAppearance, transactionMode: transactionMode)
		
		return result
	}
	
	private func customizeAppearance(for session: SessionProtocol) {
		
		ThemeManager.shared.resetCurrentThemeToDefault()
		
		guard let externalAppearance = self.externalSession?.appearance else { return }
		
		var cardInputTextStyle = Theme.current.paymentOptionsCellStyle.card.textInput
		
		if let cardInputFont = externalAppearance.cardInputFieldsFont?(for: session) {
		
			let font = Font(cardInputFont)
			
			cardInputTextStyle[.valid].font			= font
			cardInputTextStyle[.invalid].font		= font
			cardInputTextStyle[.placeholder].font	= font
		}
		
		if let validCardInputColor = externalAppearance.cardInputFieldsTextColor?(for: session) {
			
			cardInputTextStyle[.valid].color = validCardInputColor.tap_asHexColor
		}
		
		if let invalidCardInputColor = externalAppearance.cardInputFieldsInvalidTextColor?(for: session) {
			
			cardInputTextStyle[.invalid].color = invalidCardInputColor.tap_asHexColor
		}
		
		if let placeholderCardInputColor = externalAppearance.cardInputFieldsPlaceholderColor?(for: session) {
			
			cardInputTextStyle[.placeholder].color = placeholderCardInputColor.tap_asHexColor
		}
		
		Theme.current.paymentOptionsCellStyle.card.textInput = cardInputTextStyle
		
		var cardInputStyle = Theme.current.paymentOptionsCellStyle.card
		
		if let cardInputDescriptionFont = externalAppearance.cardInputDescriptionFont?(for: session) {
			
			cardInputStyle.saveCard.textStyle.font = Font(cardInputDescriptionFont)
		}
		
		if let cardInputDescriptionColor = externalAppearance.cardInputDescriptionTextColor?(for: session) {
			
			cardInputStyle.saveCard.textStyle.color = cardInputDescriptionColor.tap_asHexColor
		}
		
		if let saveCardSwitchOffTintColor = externalAppearance.cardInputSaveCardSwitchOffTintColor?(for: session) {
			
			cardInputStyle.saveCard.switchOffTintColor = saveCardSwitchOffTintColor.tap_asHexColor
		}
		
		if let saveCardSwitchOnTintColor = externalAppearance.cardInputSaveCardSwitchOnTintColor?(for: session) {
			
			cardInputStyle.saveCard.switchOnTintColor = saveCardSwitchOnTintColor.tap_asHexColor
		}
		
		if let saveCardSwitchThumbTintColor = externalAppearance.cardInputSaveCardSwitchThumbTintColor?(for: session) {
			
			cardInputStyle.saveCard.switchThumbTintColor = saveCardSwitchThumbTintColor.tap_asHexColor
		}
		
		if	let scanIconFrameTintColor = externalAppearance.cardInputScanIconFrameTintColor?(for: session),
			let tinted = cardInputStyle.scanIconFrame.tap_byApplyingTint(color: scanIconFrameTintColor) {
			
			cardInputStyle.scanIconFrame = tinted.tap_asResourceImage
		}
		
		if	let scanIconIconTintColor = externalAppearance.cardInputScanIconTintColor?(for: session),
			let tinted = cardInputStyle.scanIconIcon.tap_byApplyingTint(color: scanIconIconTintColor) {
			
			cardInputStyle.scanIconIcon = tinted.tap_asResourceImage
		}
		
		cardInputStyle.scanIcon = UIImage(byCombining: [cardInputStyle.scanIconFrame, cardInputStyle.scanIconIcon])
		
		Theme.current.paymentOptionsCellStyle.card = cardInputStyle
		
		var buttonStyles = Theme.current.buttonStyles
		
		if let buttonDisabledBackgroundColor = externalAppearance.tapButtonBackgroundColor?(for: .disabled, for: session) {
			
			let hexColor = buttonDisabledBackgroundColor.tap_asHexColor
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].disabled.backgroundColor = hexColor
			}
		}
		
		if let buttonEnabledBackgroundColor = externalAppearance.tapButtonBackgroundColor?(for: .normal, for: session) {
			
			let hexColor = buttonEnabledBackgroundColor.tap_asHexColor
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].enabled.backgroundColor = hexColor
			}
		}
		
		if let buttonHighlightedBackgroundColor = externalAppearance.tapButtonBackgroundColor?(for: .highlighted, for: session) {
			
			let hexColor = buttonHighlightedBackgroundColor.tap_asHexColor
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].highlighted.backgroundColor = hexColor
			}
		}
		
		if let buttonFont = externalAppearance.tapButtonFont?(for: session) {
			
			let font = Font(buttonFont)
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].disabled.titleStyle.font	= font
				buttonStyles[index].enabled.titleStyle.font		= font
				buttonStyles[index].highlighted.titleStyle.font	= font
			}
		}
		
		if let buttonDisabledTextColor = externalAppearance.tapButtonTextColor?(for: .disabled, for: session) {
			
			let hexColor = buttonDisabledTextColor.tap_asHexColor
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].disabled.titleStyle.color = hexColor
			}
		}
		
		if let buttonEnabledTextColor = externalAppearance.tapButtonTextColor?(for: .normal, for: session) {
			
			let hexColor = buttonEnabledTextColor.tap_asHexColor
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].enabled.titleStyle.color = hexColor
			}
		}
		
		if let buttonHighlightedTextColor = externalAppearance.tapButtonTextColor?(for: .highlighted, for: session) {
			
			let hexColor = buttonHighlightedTextColor.tap_asHexColor
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].highlighted.titleStyle.color = hexColor
			}
		}
		
		if let buttonCornerRadius = externalAppearance.tapButtonCornerRadius?(for: session) {
			
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].disabled.cornerRadius		= buttonCornerRadius
				buttonStyles[index].enabled.cornerRadius		= buttonCornerRadius
				buttonStyles[index].highlighted.cornerRadius	= buttonCornerRadius
			}
		}
		
		if let buttonLoaderVisible = externalAppearance.isLoaderVisibleOnTapButtton?(for: session) {
			
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].disabled.isLoaderVisible	= buttonLoaderVisible
				buttonStyles[index].enabled.isLoaderVisible		= buttonLoaderVisible
				buttonStyles[index].highlighted.isLoaderVisible	= buttonLoaderVisible
			}
		}
		
		if let securityIconVisible = externalAppearance.isSecurityIconVisibleOnTapButton?(for: session) {
			
			for (index, _) in buttonStyles.enumerated() {
				
				buttonStyles[index].disabled.isSecurityIconVisible		= securityIconVisible
				buttonStyles[index].enabled.isSecurityIconVisible		= securityIconVisible
				buttonStyles[index].highlighted.isSecurityIconVisible	= securityIconVisible
			}
		}
		
		Theme.current.buttonStyles = buttonStyles
	}
}

// MARK: - ImmediatelyDestroyable
extension Process: ImmediatelyDestroyable {
	
	internal static var hasAliveInstance: Bool {
		
		return self.storage != nil
	}
	
	internal static func destroyInstance() {
		
		self.storage = nil
	}
}

// MARK: - Singleton
extension Process: Singleton {
	
	internal static var shared: Process {
		
		if let nonnullStorage = self.storage {
			
			return nonnullStorage
		}
		
		let instance = Process()
		self.storage = instance
		
		return instance
	}
}