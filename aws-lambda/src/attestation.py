import os
import base64
from pyattest.configs.apple import AppleConfig
from pyattest.attestation import Attestation, PyAttestException

CERTIFICATE_AS_BYTES = os.environ['CERTIFICATE_AS_BYTES'].encode()
CERTIFICATE = base64.decodebytes(CERTIFICATE_AS_BYTES)

APP_ID = os.environ['APP_ID']
TEMP_CHALLENGE = os.environ['TEMP_CHALLENGE'].encode()
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