//
//  FundDetailScreen.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 20/08/25.
//
import SwiftUI

// MARK: - Fund Detail Screen
struct FundDetailScreen: View {
    let fund: Fund
    @StateObject private var viewModel = FundDetailViewModel()
//    @StateObject private var viewModel = ComparisonViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveAlert = false
    @State private var showingRemoveAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView("Loading fund details...")
                            .scaleEffect(1.2)
                        Text("Fetching information for")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(fund.schemeName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error Loading Details")
                            .font(.headline)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task {
                                await viewModel.fetchFundDetails(schemeCode: fund.schemeCode)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let detail = viewModel.fundDetail {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Fund Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(detail.meta.scheme_name ?? fund.schemeName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                                
                                if let fundHouse = detail.meta.fund_house {
                                    Text(fundHouse)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                }
                                
                                if let category = detail.meta.scheme_category {
                                    Text(category)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // Latest NAV
                            if let latest = detail.data.first {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current NAV")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text("₹\(latest.nav)")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("As of")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            if let date = latest.parsedDate {
                                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                Divider()
                                    .padding(.horizontal)
                            }
                            
                            // Fund Information
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Fund Information")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 8) {
                                    FundDetailRow(title: "Scheme Code", value: "\(fund.schemeCode)")
                                    
                                    if let isinGrowth = fund.isinGrowth, !isinGrowth.isEmpty {
                                        FundDetailRow(title: "ISIN Growth", value: isinGrowth)
                                    }
                                    
                                    if let isinDivReinvestment = fund.isinDivReinvestment, !isinDivReinvestment.isEmpty {
                                        FundDetailRow(title: "ISIN Dividend", value: isinDivReinvestment)
                                    }
                                    
                                    FundDetailRow(title: "Total Data Points", value: "\(detail.data.count)")
                                    
                                    if let oldest = detail.data.last,
                                       let oldestDate = oldest.parsedDate {
                                        FundDetailRow(title: "Data Available Since", value: oldestDate.formatted(date: .long, time: .omitted))
                                    }
                                    
                                    if detail.data.count >= 2,
                                       let latest = detail.data.first,
                                       let previous = detail.data.dropFirst().first,
                                       let latestValue = Double(latest.nav),
                                       let previousValue = Double(previous.nav) {
                                        let change = latestValue - previousValue
                                        let changePercent = (change / previousValue) * 100
                                        let changeText = String(format: "%.2f (%.2f%%)", change, changePercent)
                                        FundDetailRow(
                                            title: "Recent Change",
                                            value: changeText,
                                            valueColor: change >= 0 ? .green : .red
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            Spacer(minLength: 100) // Space for bottom button
                        }
                        .padding(.vertical)
                    }
                    
                    // Save Button
                    VStack {
                        Divider()
                        Button(action: handleSaveAction) {
                            HStack {
                                Image(systemName: LocalFundStorage.shared.isFundSaved(fund) ? "heart.fill" : "heart")
                                    .font(.system(size: 18))
                                Text(LocalFundStorage.shared.isFundSaved(fund) ? "Remove from My Funds" : "Save to My Funds")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LocalFundStorage.shared.isFundSaved(fund) ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Fund Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchFundDetails(schemeCode: fund.schemeCode)
        }
        .alert("Fund Saved!", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("\(fund.schemeName) has been saved to your My Funds list.")
        }
        .alert("Fund Removed", isPresented: $showingRemoveAlert) {
            Button("OK") { }
        } message: {
            Text("\(fund.schemeName) has been removed from your My Funds list.")
        }
    }
    
    private func handleSaveAction() {
        if LocalFundStorage.shared.isFundSaved(fund) {
            LocalFundStorage.shared.removeFund(fund)
            showingRemoveAlert = true
        } else {
            if let detail = viewModel.fundDetail {
                LocalFundStorage.shared.saveFund(fund, with: detail)
                showingSaveAlert = true
            }
        }
    }
}

// MARK: - Fund Detail Row Component
struct FundDetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Fund Detail ViewModel
class FundDetailViewModel: ObservableObject {
    @Published var fundDetail: FundDetailsResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchFundDetails(schemeCode: Int) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Use your existing API service
            let detail = try await FundService().fetchFundDetails(code: schemeCode)
            await MainActor.run {
                self.fundDetail = detail
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Local Fund Storage
class LocalFundStorage: ObservableObject {
    static let shared = LocalFundStorage()
    
    @Published var savedFunds: [SavedFund] = []
    
    private let userDefaults = UserDefaults.standard
    private let savedFundsKey = "SavedFunds"
    
    private init() {
        loadSavedFunds()
    }
    
    func saveFund(_ fund: Fund, with detail: FundDetailsResponse) {
        let savedFund = SavedFund(
            schemeCode: fund.schemeCode,
            schemeName: fund.schemeName,
            isinGrowth: fund.isinGrowth,
            isinDivReinvestment: fund.isinDivReinvestment,
            fundHouse: detail.meta.fund_house,
            schemeCategory: detail.meta.scheme_category,
            latestNAV: detail.data.first?.nav,
            latestNAVDate: detail.data.first?.parsedDate,
            savedDate: Date()
        )
        
        // Remove if already exists and add new one
        savedFunds.removeAll { $0.schemeCode == fund.schemeCode }
        savedFunds.append(savedFund)
        persistSavedFunds()
    }
    
    func removeFund(_ fund: Fund) {
        savedFunds.removeAll { $0.schemeCode == fund.schemeCode }
        persistSavedFunds()
    }
    
      func removeAllFunds() {
          savedFunds.removeAll()
          persistSavedFunds()
      }
    
    func isFundSaved(_ fund: Fund) -> Bool {
        savedFunds.contains { $0.schemeCode == fund.schemeCode }
    }
    
    private func loadSavedFunds() {
        if let data = userDefaults.data(forKey: savedFundsKey),
           let decoded = try? JSONDecoder().decode([SavedFund].self, from: data) {
            savedFunds = decoded
        }
    }
    
    private func persistSavedFunds() {
        if let encoded = try? JSONEncoder().encode(savedFunds) {
            userDefaults.set(encoded, forKey: savedFundsKey)
        }
    }
}

// MARK: - Saved Fund Model
struct SavedFund: Codable, Identifiable {
    let id = UUID()
    let schemeCode: Int
    let schemeName: String
    let isinGrowth: String?
    let isinDivReinvestment: String?
    let fundHouse: String?
    let schemeCategory: String?
    let latestNAV: String?
    let latestNAVDate: Date?
    let savedDate: Date
}

extension SavedFund {
    func toFund() -> Fund {
        Fund(
            schemeCode: schemeCode,
            schemeName: schemeName,
            isinGrowth: isinGrowth,
            isinDivReinvestment: isinDivReinvestment
        )
    }
}

struct FundDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        FundDetailScreen(fund: Fund(schemeCode: 100028, schemeName: "Sample Fund", isinGrowth: nil, isinDivReinvestment: nil))
    }
}
