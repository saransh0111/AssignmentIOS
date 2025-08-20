//
//  MyFunds.swift
//  Assignment_ios
//
//  Created by Saransh Nirmalkar on 20/08/25.
//
import SwiftUI

struct MyFundsScreen: View {
    @StateObject private var localStorage = LocalFundStorage.shared
    @State private var selectedFunds: [Fund] = []
    @State private var navigateToComparison = false
    @State private var searchText: String = ""
    @State private var showingDeleteAlert = false
    @State private var fundToDelete: SavedFund?
    @State private var showingFundDetail = false
    @State private var selectedFundForDetail: Fund?
    
    private var filteredFunds: [SavedFund] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return localStorage.savedFunds.sorted { $0.savedDate > $1.savedDate }
        }
        return localStorage.savedFunds
            .filter { $0.schemeName.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.savedDate > $1.savedDate }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                if !localStorage.savedFunds.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search saved funds...", text: $searchText)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                if localStorage.savedFunds.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Saved Funds")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Long press on any fund in the Funds list to save it to your favorites")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Optional: Add button to go to funds screen
                        Button("Browse Funds") {
                            // You can add navigation logic here if needed
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Funds List
                    List {
                        ForEach(filteredFunds) { savedFund in
                            SavedFundCardView(
                                savedFund: savedFund,
                                isSelected: selectedFunds.contains { $0.schemeCode == savedFund.schemeCode },
                                onTap: { toggleSelection(savedFund.toFund()) },
                                onLongPress: { showFundDetail(savedFund.toFund()) },
                                onDelete: { showDeleteAlert(for: savedFund) }
                            )
                        }
                    }
                    .listStyle(.plain)
                    
                    // Compare Button
                    if !selectedFunds.isEmpty {
                        VStack {
                            Divider()
                            
                            let enabled = selectedFunds.count >= 2 && selectedFunds.count <= 4
                            Button {
                                navigateToComparison = true
                            } label: {
                                Text(enabled ? "Compare (\(selectedFunds.count))" : selectedFunds.count == 1 ? "Select one more fund to compare" : "Select 2–4 funds to compare")
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
                        }
                        .background(Color(.systemBackground))
                    }
                }
                
                // Hidden Navigation
                NavigationLink(destination: ComparisonScreen(selectedFunds: selectedFunds), isActive: $navigateToComparison) {
                    EmptyView()
                }
            }
            .navigationTitle("My Funds")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !selectedFunds.isEmpty {
                        Button("Clear") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFunds.removeAll()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingFundDetail) {
                if let fund = selectedFundForDetail {
                    FundDetailScreen(fund: fund)
                }
            }
        }
        .alert("Remove Fund", isPresented: $showingDeleteAlert) {
            Button("Remove", role: .destructive) {
                if let fund = fundToDelete {
                    removeFund(fund)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let fund = fundToDelete {
                Text("Are you sure you want to remove \(fund.schemeName) from your saved funds?")
            }
        }
    }
    
    private func toggleSelection(_ fund: Fund) {
        if let index = selectedFunds.firstIndex(where: { $0.schemeCode == fund.schemeCode }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFunds.remove(at: index)
            }
        } else if selectedFunds.count < 4 {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFunds.append(fund)
            }
        }
    }
    
    private func showFundDetail(_ fund: Fund) {
        selectedFundForDetail = fund
        showingFundDetail = true
    }
    
    private func showDeleteAlert(for fund: SavedFund) {
        fundToDelete = fund
        showingDeleteAlert = true
    }
    
    private func removeFund(_ savedFund: SavedFund) {
        withAnimation(.easeInOut(duration: 0.3)) {
            localStorage.removeFund(savedFund.toFund())
            selectedFunds.removeAll { $0.schemeCode == savedFund.schemeCode }
        }
        fundToDelete = nil
    }
}

// MARK: - Saved Fund Card View
struct SavedFundCardView: View {
    let savedFund: SavedFund
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection Indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Fund Info
            VStack(alignment: .leading, spacing: 6) {
                Text(savedFund.schemeName)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    if let fundHouse = savedFund.fundHouse {
                        Text(fundHouse)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    
                    if savedFund.fundHouse != nil && savedFund.schemeCategory != nil {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let category = savedFund.schemeCategory {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    if let latestNAV = savedFund.latestNAV {
                        Text("₹\(latestNAV)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else {
                        Text("Code: \(savedFund.schemeCode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if let navDate = savedFund.latestNAVDate {
                            Text("NAV: \(navDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Saved: \(savedFund.savedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Options Menu
            Menu {
                Button {
                    onLongPress()
                } label: {
                    Label("View Details", systemImage: "info.circle")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove from My Funds", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct MyFundsScreen_Previews: PreviewProvider {
    static var previews: some View {
        MyFundsScreen()
    }
}
