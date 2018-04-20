//
//  APIClient.swift
//  goSellSDK
//
//  Copyright © 2018 Tap Payments. All rights reserved.
//

import class TapApplication.ApplicationPlistInfo
import func TapSwiftFixes.performOnBackgroundThread
import func TapSwiftFixes.performOnMainThread
import class TapNetworkManager.TapNetworkManager
import class TapNetworkManager.TapNetworkRequestOperation

/// API client.
internal class APIClient {
    
    // MARK: - Internal -
    
    internal typealias Completion<Response> = (Response?, TapSDKError?) -> Void
    
    // MARK: Properties
    
    internal static let shared = APIClient()
    
    /// Static HTTP headers sent with each request.
    internal var staticHTTPHeaders: [String: String] {
        
        let secretKey = goSellSDK.secretKey
        
        guard secretKey.length > 0 else {
            
            fatalError("Secret key must be set in order to use goSellSDK.")
        }
        
        let bundleID = ApplicationPlistInfo.shared.bundleIdentifier
        
        guard bundleID.length > 0 else {
            
            fatalError("Application must have bundle identifier in order to use goSellSDK.")
        }
        
        return [
            
            Constants.HTTPHeaderKey.authorization: "Bearer \(secretKey)",
            Constants.HTTPHeaderKey.application: bundleID
        ]
    }
    
    // MARK: Methods
    
    /// Performs request.
    ///
    /// - Parameters:
    ///   - operation: Request operation.
    ///   - decoder: Response decoder.
    ///   - checkSDKInitializationStatus: Defines if SDK initialization status is checked before the request.
    ///   - completion: Completion closure.
    ///   - response: Response object in case of success.
    ///   - error: Error in case of failure.
    internal func performRequest<Response>(_ operation: TapNetworkRequestOperation, using decoder: JSONDecoder, checkSDKInitializationStatus: Bool = true, completion: @escaping Completion<Response>) where Response: Decodable {
        
        performOnBackgroundThread { [unowned self] in
            
            let requestClosure: SettingsDataManager.OptionalErrorClosure = { initializationError in
                
                guard initializationError == nil else {
                    
                    performOnMainThread {
                        
                        completion(nil, initializationError)
                    }
                    
                    return
                }
                
                self.networkManager.performRequest(operation) { (dataTask, response, error) in
                    
                    self.handleResponse(response, error: error, in: dataTask, using: decoder, completion: completion)
                }
            }
            
            if checkSDKInitializationStatus {
                
                SettingsDataManager.shared.checkInitializationStatus(requestClosure)
            }
            else {
                
                requestClosure(nil)
            }
        }
    }
    
    /// Converts Encodable model into its dictionary representation. Calls completion closure in case of failure.
    ///
    /// - Parameters:
    ///   - model: Model to encode.
    ///   - completion: Failure completion closure.
    ///   - response: Response object in case of success. Here - always nil.
    ///   - error: Error in case of failure. If the closure is called it will never become nil.
    /// - Returns: Dictionary.
    internal func convertModelToDictionary<Response>(_ model: Encodable, callingCompletionOnFailure completion: Completion<Response>) -> [String: Any]? where Response: Decodable {
        
        var modelDictionary: [String: Any]
        
        do {
            
            modelDictionary = try model.asDictionary()
        }
        catch let error {
            
            completion(nil, TapSDKKnownError(type: .serialization, error: error, response: nil))
            return nil
        }
        
        return modelDictionary
    }
    
    // MARK: - Private -
    
    private struct Constants {
        
        fileprivate static let baseURL: URL = {
            
            guard let result = URL(string: Constants.baseURLString) else {
                
                fatalError("Wrong base URL: \(Constants.baseURLString)")
            }
            
            return result
        }()
        
        fileprivate static let successStatusCodes = 200...299
        
        fileprivate struct HTTPHeaderKey {
            
            fileprivate static let authorization = "Authorization"
            fileprivate static let application = "application"
            
            @available(*, unavailable) private init() { }
        }
        
        private static let baseURLString = "https://api.tap.company/v1/"
        
        @available(*, unavailable) private init() { }
    }
    
    // MARK: Properties
    
    private let networkManager = TapNetworkManager(baseURL: Constants.baseURL)
    
    // MARK: Methods
    
    private init() {}
    
    private func handleResponse<Response>(_ response: Any?, error: Error?, in dataTask: URLSessionDataTask?, using decoder: JSONDecoder, completion: @escaping Completion<Response>) where Response: Decodable {
        
        if let nonnullError = error {
            
            performOnMainThread {
                
                completion(nil, TapSDKKnownError(type: .network, error: nonnullError, response: dataTask?.response))
            }
            return
        }
        
        if let dataTaskError = dataTask?.error {
            
            performOnMainThread {
                
                completion(nil, TapSDKKnownError(type: .network, error: dataTaskError, response: dataTask?.response))
            }
            
            return
        }
        
        if let dictionary = response as? [String: Any], let httpResponse = dataTask?.response as? HTTPURLResponse {
            
            let statusCode = httpResponse.statusCode
            if Constants.successStatusCodes.contains(statusCode) {
                
                do {
                    
                    let parsedResponse = try Response(dictionary: dictionary, using: decoder)
                    performOnMainThread {
                        
                        completion(parsedResponse, nil)
                    }
                    
                    return
                }
                catch let parsingError {
                    
                    performOnMainThread {
                        
                        completion(nil, TapSDKKnownError(type: .serialization, error: parsingError, response: httpResponse))
                    }
                    
                    return
                }
            }
            else {
                
                do {
                    
                    let parsedError = try APIError(dictionary: dictionary, using: decoder)
                    
                    performOnMainThread {
                        
                        completion(nil, TapSDKAPIError(error: parsedError, response: httpResponse))
                    }
                    
                    return
                }
                catch let parsingError {
                    
                    performOnMainThread {
                        
                        completion(nil, TapSDKKnownError(type: .serialization, error: parsingError, response: httpResponse))
                    }
                    
                    return
                }
            }
        }
        else {
            
            performOnMainThread {
                
                completion(nil, TapSDKUnknownError(dataTask: dataTask))
            }
            
            return
        }
    }
}