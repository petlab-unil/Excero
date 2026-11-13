//
//  ApiFacade.swift
//  excero
//
//  Created by Alessandro Silacci on 23.03.23.
//

import Foundation
import UIKit

public protocol ApiFacade: AnyObject {
    var url: String { get }
    
    var header: Dictionary<String, String> { get }
        
    init(url: String, header: Dictionary<String, String>)
    
    func get(endpointPath: String, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async
    
    func get(endpointPath: String, header: Dictionary<String, String>?) async throws -> Data?
    
    func get(fullUrl: String, header: Dictionary<String, String>?) async throws -> Data? 
    
    //func get(endpointPath: String, index: AnyObject, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async
    //func post(endpointPath: String, data: Codable, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async
    
    func post(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async
    
    func post(fullUrl: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async
    
    func post(fullUrl: String, data: Codable, header: Dictionary<String, String>?) async throws -> Data?
    
    func post(fullUrl: String, data: Any, header: Dictionary<String, String>?) async throws -> Data?
    
    func postFormData(endpointPath: String, file: Data, additionalData: Dictionary<String, String>?, header: Dictionary<String, String>?) async throws -> Data?
    
    func postFormData(fullUrl: String, file: Data, additionalData: Dictionary<String, String>?, header: Dictionary<String, String>?) async throws -> Data?
    
    func put(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async
    
    func delete(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async
    
    func prepareImagesForSend(files: Dictionary<String, UIImage>) -> Data
}

public extension ApiFacade {
    
    private func createMultipartBody(file: Data, additionalData: Dictionary<String, String>?, boundary: String, filename: String) -> Data {
        let body = NSMutableData()
        let lineBreak = "\r\n"
        let prefix = "--\(boundary) \(lineBreak)"
        if let additionalData = additionalData {
            var additionalDataString: String = ""
            for key in additionalData.keys {
                additionalDataString += "\(prefix)Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)\(additionalData[key] ?? "")\(lineBreak)"
            }
            body.append(additionalDataString.data(using: .utf8)!)
        }
        body.append(prefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(filename)\"; filename=\"\(filename)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: text/plain\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(file)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        
        return body as Data
    }
    
    func get(endpointPath: String, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async {
        guard let url = URL(string: self.url + endpointPath) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: handler)
        task.resume()
        
    }
    
    func get(fullUrl: String, header: Dictionary<String, String>?) async throws -> Data? {
        guard let url = URL(string: fullUrl) else { return nil }
        //let semaphore = DispatchSemaphore(value: 0)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let (_data, _urlRes) = try await URLSession.shared.data(for: request)
        switch((_urlRes as? HTTPURLResponse)?.statusCode) {
        case 401: throw ApiError.unauthorizedError("Unauthorized connection to resource on \(fullUrl)")
        case 500: throw ApiError.serverError("Internal server error on GET request to \(fullUrl)")
        case 200: return _data
        default: throw ApiError.defaultApiError("An error occured in the GET request to \(fullUrl)")
        }

    }
    
    func get(endpointPath: String, header: Dictionary<String, String>?) async throws -> Data? {
        return try await self.get(fullUrl: self.url + endpointPath, header: header)

    }
    
    func post(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async {
        await self.post(fullUrl: self.url + endpointPath, data: data, header: header, handler: handler)
    }
    
    func post(endpointPath: String, data: Any, header: Dictionary<String, String>?) async throws -> Data? {
        return try await self.post(fullUrl: self.url + endpointPath, data: data, header: header)
    }
    
    func post(endpointPath: String, data: Codable, header: Dictionary<String, String>?) async throws -> Data? {
        return try await self.post(fullUrl: self.url + endpointPath, data: data, header: header)
    }
    
    func postFormData(endpointPath: String, file: Data, additionalData: Dictionary<String, String>? = nil, header: Dictionary<String, String>?) async throws -> Data? {
        return try await self.postFormData(fullUrl: self.url + endpointPath, file: file, additionalData: additionalData, header: header)
    }
    
    func post(fullUrl: String, data: Codable, header: Dictionary<String, String>?) async throws -> Data? {
        guard let url = URL(string: fullUrl) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(data)
        let jsonString = String(data: jsonData, encoding: .utf8)
        request.httpBody = jsonData
        let (_data, _urlRes) = try await URLSession.shared.data(for: request)
        switch((_urlRes as? HTTPURLResponse)?.statusCode) {
        case 401: throw ApiError.unauthorizedError("Unauthorized connection to resource on \(fullUrl)")
        case 500: throw ApiError.serverError("Internal server error on POST request to \(fullUrl)")
        case 200: return _data
        case 201: return _data
        default: throw ApiError.defaultApiError("An error occured in the POST request to \(fullUrl)")
        }
    }
    
    func post(fullUrl: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async {
        guard let url = URL(string: fullUrl) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        let task = URLSession.shared.dataTask(with: request, completionHandler: handler)
        task.resume()
        
    }
    
    func post(fullUrl: String, data: Any, header: Dictionary<String, String>?) async throws -> Data? {
        guard let url = URL(string: fullUrl) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        let (_data, _urlRes) = try await URLSession.shared.data(for: request)
        switch((_urlRes as? HTTPURLResponse)?.statusCode) {
        case 401: throw ApiError.unauthorizedError("Unauthorized connection to resource on \(fullUrl)")
        case 500: throw ApiError.serverError("Internal server error on POST request to \(fullUrl)")
        case 200: return _data
        default: throw ApiError.defaultApiError("An error occured in the POST request to \(fullUrl)")
        }
    }
    
    func postFormData(fullUrl: String, file: Data, additionalData: Dictionary<String,String>? = nil, header: Dictionary<String, String>?) async throws -> Data? {
        guard let url = URL(string: fullUrl) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        let boundary = "Boundary-(\(UUID().uuidString))"
        request.setValue("multipart/form-data; boundary=\"\(boundary)\"", forHTTPHeaderField: "Content-Type")
        let requestBody = self.createMultipartBody(file: file, additionalData: additionalData, boundary: boundary, filename: "app_logs")
        request.httpBody = requestBody
        let (_data, _urlRes) = try await URLSession.shared.data(for: request)
        switch((_urlRes as? HTTPURLResponse)?.statusCode) {
        case 401: throw ApiError.unauthorizedError("Unauthorized connection to resource on \(fullUrl)")
        case 500: throw ApiError.serverError("Internal server error on POST request to \(fullUrl)")
        case 200: return _data
        default: throw ApiError.defaultApiError("An error occured in the POST request to \(fullUrl)")
        }
    }
    
    func put(fullUrl: String, data: Codable, header: Dictionary<String, String>?) async throws -> Data? {
        guard let url = URL(string: fullUrl) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(data)
        let jsonString = String(data: jsonData, encoding: .utf8)
        request.httpBody = jsonData
        let (_data, _urlRes) = try await URLSession.shared.data(for: request)
        switch((_urlRes as? HTTPURLResponse)?.statusCode) {
        case 401: throw ApiError.unauthorizedError("Unauthorized connection to resource on \(fullUrl)")
        case 500: throw ApiError.serverError("Internal server error on POST request to \(fullUrl)")
        case 200: return _data
        default: throw ApiError.defaultApiError("An error occured in the POST request to \(fullUrl)")
        }
    }
    
    func put(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async {
        guard let url = URL(string: self.url + endpointPath) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        let task = URLSession.shared.dataTask(with: request, completionHandler: handler)
        task.resume()
    }
    
    func delete(endpointPath: String, data: Any, header: Dictionary<String, String>?, handler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) async {
        guard let url = URL(string: self.url + endpointPath) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let headerParams = header {
            headerParams.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        else {
            self.header.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        let task = URLSession.shared.dataTask(with: request, completionHandler: handler)
        task.resume()
    }
}

/*public extension ApiFacade {
    func prepare
}*/

public class Api: ApiFacade {
    public func prepareImagesForSend(files: Dictionary<String, UIImage>) -> Data {
        return Data()
    }
    
    public var url: String
    
    public var header: Dictionary<String, String>
    
    public required init(url: String, header: Dictionary<String, String>) {
        self.url = url
        self.header = header
    }
}


