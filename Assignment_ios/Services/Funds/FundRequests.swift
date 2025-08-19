//
//  FundRequests.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//

import Foundation

enum FundRequests {
    
    struct GetAllFunds: Endpoint {
        typealias Response = [Fund]
        var path: String { "mf" }
        var method: HTTPMethod { .GET }
        var headers: [String : String]? { ["Content-Type": "application/json"] }
    }
    
    struct GetFundDetails: Endpoint {
        typealias Response = FundDetailsResponse
        var path: String { "mf/\(schemeCodeString)" }
        var method: HTTPMethod { .GET }
        var headers: [String : String]? { ["Content-Type": "application/json"] }
        
        let schemeCodeString: String
        
        // Convenience initializers
        init(schemeCode: Int) { self.schemeCodeString = String(schemeCode) }
        init(schemeCode: String) { self.schemeCodeString = schemeCode }
    }
}

