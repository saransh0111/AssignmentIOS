//
//  Endpoints.swift
//  WOFA
//
//  Created by Saransh Nirmalkar on 07/05/25.
//

import Foundation

/// Describes any API endpoint (path, method, queries, headers, body, content type)
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryParameters: [String: String]? { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var contentType: String? { get }
}

extension Endpoint {
    var queryParameters: [String: String]? { nil }
    var headers: [String: String]? { nil }
    var body: Data? { nil }
    var contentType: String? { nil }
}
