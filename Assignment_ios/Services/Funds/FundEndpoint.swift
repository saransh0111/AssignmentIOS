//
//  FundEndpoint.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//
import Foundation

/// API Endpoints for Mutual Fund related operations
enum FundEndpoint {
    case fundDetails(code: String)
}

// MARK: - Endpoint Conformance
extension FundEndpoint: Endpoint {
    var path: String {
        switch self {
        case .fundDetails(let code):
            return "mf/\(code)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .fundDetails:
            return .GET
        }
    }
    
    var queryParameters: [String: String]? {
        switch self {
        case .fundDetails:
            return nil
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .fundDetails:
            return nil
        }
    }
}

