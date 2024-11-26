//
//  AttestManager.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/19/24.
//

import Foundation
import DeviceCheck
import CryptoKit

class AppAttestManager {
    struct AttestationResult {
        let keyID: String
        let attestationObjectBase64: String
    }
    
    static func requestChallenge(keyID: String) async throws -> String? {
        #if targetEnvironment(simulator)
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "App Attest not supported on simulator."])
        #else
        let jsonData = try JSONSerialization.data(withJSONObject: [
            "key_id": keyID
        ])

        guard let url = URL(string: Configuration.apiUrl), !Configuration.apiUrl.isEmpty else {
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Configuration.apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to request challenge"])
        }

        do {
            let decoder = JSONDecoder()
            let responseModel = try decoder.decode(LambdaResponseModel.self, from: data)
            
            guard let challenge = responseModel.body.challenge else {
                print("Challenge not found in response")
                return nil
            }
            
            print("Challenge: \(challenge)")
            return challenge
        } catch {
            print("Failed to decode JSON: \(error.localizedDescription)")
            return nil
        }
        
        #endif
    }
    
    static func performAttest() async throws -> AttestationResult {
        #if targetEnvironment(simulator)
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "App Attest not supported on simulator."])
        #else
        let service = DCAppAttestService.shared

        guard service.isSupported else {
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "App Attest not supported on this device."])
        }

        // Generate a new key if none exists
        guard let challenge = try await requestChallenge(keyID: keyID) else {
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to request challenge"])
        }
    
        let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))
        
        let attestationObject: Data = try await withCheckedThrowingContinuation { continuation in
            service.attestKey(keyID, clientDataHash: clientDataHash) { attestation, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let attestation = attestation {
                    continuation.resume(returning: attestation)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppAttest", code: -1, userInfo: nil))
                }
            }
        }
        let attestationObjectBase64 = attestationObject.base64EncodedString()

        return AttestationResult(keyID: keyID, attestationObjectBase64: attestationObjectBase64)
        #endif
    }
}
