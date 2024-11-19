//
//  Attest.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/19/24.
//

import DeviceCheck
import CryptoKit

struct AttestationResult {
    let keyId: String?
    let attestationObject: String?
}

func getAttestationData() async -> AttestationResult! {
    // App Attest Service
    let service = DCAppAttestService.shared
    
    // TODO: Make attest available on simulator
    let challengeString = Configuration.challenge
    let clientDataHash = Data(SHA256.hash(data: Data(challengeString.utf8)))
//    let userDefaults = UserDefaults.standard
    let keyIDKey = "appAttestKeyID"
    var keyID: String? = nil // userDefaults.string(forKey: keyIDKey)
    var attestationObjectBase64: String? = nil

    #if targetEnvironment(simulator)
    // Simulator bypass
    keyID = "simulatorTest-\(keyIDKey)"
    // Create a mock assertion
    attestationObjectBase64 = "mock_attestation".data(using: .utf8)?.base64EncodedString()

    #else
    guard service.isSupported else {
        print("App Attest not supported on this device")
        return nil
    }
    
    do {
        if keyID == nil {
            // Generate a new key
            keyID = try await withCheckedThrowingContinuation { continuation in
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
            // Store key ID in local storage
//            userDefaults.set(keyID, forKey: keyIDKey)
        }
        
        let attestationObject: Data = try await withCheckedThrowingContinuation { continuation in
            // attestation happens here
            service.attestKey(keyID!, clientDataHash: clientDataHash) { attestation, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let attestation = attestation {
                    continuation.resume(returning: attestation)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppAttest", code: -1, userInfo: nil))
                }
            }
        }
        attestationObjectBase64 = attestationObject.base64EncodedString()
        
        let response = AttestationResult(keyId: keyID, attestationObject: attestationObjectBase64)
        return response
    } catch {
        print("Attestation failed")
    }

    #endif
    
    return nil
}
