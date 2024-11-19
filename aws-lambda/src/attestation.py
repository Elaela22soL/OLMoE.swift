import base64
from pyattest.configs.apple import AppleConfig
from pyattest.attestation import Attestation, PyAttestException

CERTIFICATE_AS_BYTES = b'MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYwJAYDVQQDDB1BcHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwKQXBwbGUgSW5jLjETMBEGA1UECAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNaFw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMMHUFwcGxlIEFwcCBBdHRlc3RhdGlvbiBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYDVQQIDApDYWxpZm9ybmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dyctdhNbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9auYen1mMEvRq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSskRBTM72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZIzj0EAwMDaAAwZQIwQgFGnByvsiVbpTKwSga0kP0e8EeDS4+sQmTvb7vn53O5+FRXgeLhpJ06ysC5PrOyAjEAp5U4xDgEgllF7En3VcE3iexZZtKeYnpqtijVoyFraWVIyd/dganmrduC1bmTBGwD'
CERTIFICATE = base64.decodebytes(CERTIFICATE_AS_BYTES)

APP_ID = 'MJLARYDQWH.com.genui.ai2.olmoe'
TEMP_CHALLENGE = b'STATIC_CHALLENGE_RECEIVED_FROM_SERVER'
IS_PRODUCTION = True

def verify_attest(key_id: str, attestation_object: str) -> bool:
    """
    Verify the attestation object from Apple WebAuthn
    """
    key_id_bytes = base64.b64decode(key_id)
    attest = base64.b64decode(attestation_object)
    nonce = TEMP_CHALLENGE
    config = AppleConfig(
        key_id=key_id_bytes,
        app_id=APP_ID,
        production=IS_PRODUCTION,
        root_ca=CERTIFICATE
    )
    attestation = Attestation(attest, nonce, config)

    try:
        attestation.verify()
        return True
    except PyAttestException:
        print("Error verifying attestation")
        return False
    except Exception as e:
        print("Error while parsing attestation object", e)
        return False