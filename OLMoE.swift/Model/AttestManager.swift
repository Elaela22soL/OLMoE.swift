//
//  Attest.swift
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
    
    static func performAttest(challengeString: String) async throws -> AttestationResult {
        #if targetEnvironment(simulator)
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "App Attest not supported on simulator."])
        #else
        let service = DCAppAttestService.shared

        guard service.isSupported else {
            throw NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "App Attest not supported on this device."])
        }

        let clientDataHash = Data(SHA256.hash(data: Data(challengeString.utf8)))

        // Generate a new key if none exists
        let keyID: String = try await withCheckedThrowingContinuation { continuation in
            service.generateKey { newKeyID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let newKeyID = newKeyID {
                    continuation.resume(returning: newKeyID)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppAttest", code: -1, userInfo: nil))
                }
            }
        }

        let attestationObject: Data = try await withCheckedThrowingContinuation { continuation in
            // attestation happens here
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
