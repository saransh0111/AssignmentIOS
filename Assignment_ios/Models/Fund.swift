//
//  Funds.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//
import Foundation

struct Fund: Codable, Identifiable, Equatable {
    var id: Int { schemeCode }   // use schemeCode as stable ID
    let schemeCode: Int
    let schemeName: String
    let isinGrowth: String?
    let isinDivReinvestment: String?
    
    enum CodingKeys: String, CodingKey {
        case schemeCode = "schemeCode"
        case schemeName = "schemeName"
        case isinGrowth = "isinGrowth"
        case isinDivReinvestment = "isinDivReinvestment"
    }
}

