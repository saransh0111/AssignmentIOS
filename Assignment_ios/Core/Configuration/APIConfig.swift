//
//  APIConfig.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//
import Foundation

enum APIConfig {
    static let baseURL = "https://api.mfapi.in"
    
    enum ContentType {
        static let json = "application/json"
    }
    
    enum Headers {
        static let contentType = "Content-Type"
        static let accept = "Accept"
    }
}

