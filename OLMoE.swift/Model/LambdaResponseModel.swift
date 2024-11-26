//
//  LambdaResponseModel.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/25/24.
//

import Foundation

struct LambdaResponseModel: Codable {
    let statusCode: Int
    let body: NestedBody
    
    struct NestedBody: Codable {
        let challenge: String?
        let outcome: String?
        let error: String?
        let url: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case body
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        
        let bodyString = try container.decode(String.self, forKey: .body)
        if let bodyData = bodyString.data(using: .utf8) {
            let nestedBody = try JSONDecoder().decode(NestedBody.self, from: bodyData)
            self.body = nestedBody
        } else {
            throw DecodingError.dataCorruptedError(forKey: .body,
                                                   in: container,
                                                   debugDescription: "Body string is not valid JSON")
        }
    }
}
