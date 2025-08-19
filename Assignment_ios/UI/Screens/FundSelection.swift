//
//  FundSelection.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 19/08/25.
//

import SwiftUI

struct FundSelection: View {
    @StateObject private var viewModel = FundViewModel()
    @State private var selectedFunds: [Fund] = []
    @State private var searchText: String = ""
    @State private var navigateToComparison = false
    
    private var filteredFunds: [Fund] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.funds
        }
        return viewModel.funds.filter { $0.schemeName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search funds...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.gray))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else {
                    List(filteredFunds, id: \.schemeCode) { fund in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fund.schemeName).font(.headline)
                                Text("Code: \(fund.schemeCode)").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            let isSelected = selectedFunds.contains { $0.schemeCode == fund.schemeCode }
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? .blue : .gray)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .background((selectedFunds.contains { $0.schemeCode == fund.schemeCode } ? Color.blue.opacity(0.1) : .clear).cornerRadius(8))
                        .onTapGesture { toggleSelection(fund) }
                    }
                    .listStyle(.plain)
                }
                
                // Compare button
                let enabled = selectedFunds.count >= 2 && selectedFunds.count <= 4
                Button {
                    navigateToComparison = true
                } label: {
                    Text(enabled ? "Compare (\(selectedFunds.count))" : "Select 2–4 funds to compare")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(enabled ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(!enabled)
                .padding(.bottom)
                
                // Hidden navigation
                NavigationLink(destination: ComparisonScreen(selectedFunds: selectedFunds), isActive: $navigateToComparison) {
                    EmptyView()
                }
            }
            .navigationTitle("Funds")
            .task { await viewModel.fetchFunds() }
        }
    }
    
    private func toggleSelection(_ fund: Fund) {
        if let idx = selectedFunds.firstIndex(where: { $0.schemeCode == fund.schemeCode }) {
            selectedFunds.remove(at: idx)
        } else if selectedFunds.count < 4 {
            selectedFunds.append(fund)
        }
    }
}



struct FundSelection_Previews: PreviewProvider {
    static var previews: some View {
        FundSelection()
    }
}
