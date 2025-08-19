//
//  FundViewModel.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.


import Foundation

@MainActor
class FundViewModel: ObservableObject {
    @Published var funds: [Fund] = []
    @Published var fundDetails: [FundDetailsResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let api = APIService.shared
    
    func fetchFunds() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let endpoint = FundRequests.GetAllFunds()
            funds = try await api.request(endpoint)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchFundDetails(for selectedFunds: [Fund]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        var details: [FundDetailsResponse] = []
        for fund in selectedFunds {
            do {
                let endpoint = FundRequests.GetFundDetails(schemeCode: fund.schemeCode)
                let detail: FundDetailsResponse = try await api.request(endpoint)
                details.append(detail)
            } catch {
                print("Error fetching details for \(fund.schemeCode): \(error)")
            }
        }
        fundDetails = details
    }
}


