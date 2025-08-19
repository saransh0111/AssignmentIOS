//
//  FundService.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//


// FundService.swift
import Foundation

actor FundService {
    private let api = APIService.shared

    func fetchFunds() async throws -> [Fund] {
        let request = FundRequests.GetAllFunds()
        return try await api.request(request)
    }

    func fetchFundDetails(code: Int) async throws -> FundDetailsResponse {
        let request = FundRequests.GetFundDetails(schemeCode: code)
        return try await api.request(request)
    }
}

