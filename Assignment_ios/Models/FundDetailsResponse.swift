import Foundation

// MARK: - Fund Details Models
struct FundDetailsResponse: Codable {
    let meta: FundMeta
    let data: [FundNav]
}

struct FundMeta: Codable {
    let fund_house: String?
    let scheme_type: String?
    let scheme_category: String?
    let scheme_code: Int?
    let scheme_name: String?
    let isin_growth: String?
    let isin_div_reinvestment: String?
}

struct FundNav: Codable {
    let date: String
    let nav: String
    
    var navValue: Double {
        return Double(nav) ?? 0.0
    }
    
    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.date(from: date)
    }
}
