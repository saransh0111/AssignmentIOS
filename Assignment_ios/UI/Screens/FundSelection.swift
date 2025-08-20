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
    @State private var selectedFundForDetail: Fund?
    @State private var showingFundDetail = false
    
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
                .background(Color(.systemGray5))
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
                        FundCardView(
                            fund: fund,
                            isSelected: selectedFunds.contains { $0.schemeCode == fund.schemeCode },
                            onTap: { toggleSelection(fund) },
                            onLongPress: { showFundDetail(fund) }
                        )
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
            .sheet(isPresented: $showingFundDetail) {
                if let fund = selectedFundForDetail {
                    FundDetailScreen(fund: fund)
                }
            }
        }
    }
    
    private func toggleSelection(_ fund: Fund) {
        if let idx = selectedFunds.firstIndex(where: { $0.schemeCode == fund.schemeCode }) {
            selectedFunds.remove(at: idx)
        } else if selectedFunds.count < 4 {
            selectedFunds.append(fund)
        }
    }
    
    private func showFundDetail(_ fund: Fund) {
        selectedFundForDetail = fund
        showingFundDetail = true
    }
}

// MARK: - Fund Card View
struct FundCardView: View {
    let fund: Fund
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fund.schemeName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                Text("Code: \(fund.schemeCode)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onLongPress()
        }
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct FundSelection_Previews: PreviewProvider {
    static var previews: some View {
        FundSelection()
    }
}
