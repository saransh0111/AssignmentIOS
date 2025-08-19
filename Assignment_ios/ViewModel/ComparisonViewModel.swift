//
//  ComparisonViewModel.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//
import SwiftUI
@MainActor
class ComparisonViewModel: ObservableObject {
    @Published var fundDetails: [Int: FundDetailsResponse] = [:] // schemeCode -> details
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    /// Fetch details for multiple selected funds
    func fetchFundDetails(for funds: [Fund]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Fetch details concurrently
            try await withThrowingTaskGroup(of: (Int, FundDetailsResponse).self) { group in
                for fund in funds {
                    // Skip already fetched
                    if fundDetails[fund.schemeCode] != nil { continue }

                    group.addTask {
                        let detail: FundDetailsResponse = try await self.api.request(FundRequests.GetFundDetails(schemeCode: fund.schemeCode))
                        return (fund.schemeCode, detail)
                    }
                }

                for try await (schemeCode, detail) in group {
                    fundDetails[schemeCode] = detail
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching fund details: \(error)")
        }
    }
}




