import os
import base64
import hashlib
import hmac

from pyattest.configs.apple import AppleConfig
from pyattest.attestation import Attestation, PyAttestException

from constants.response_messages import ResponseMessages
from constants.deployment_environment import DeploymentEnvironment

CERTIFICATE_AS_BYTES = os.environ['CERTIFICATE_AS_BYTES'].encode()
CERTIFICATE = base64.decodebytes(CERTIFICATE_AS_BYTES)

APP_ID = os.environ['APP_ID']
DEPLOYMENT_ENV = DeploymentEnvironment.from_env()

def verify_attest(key_id: str, attestation_object: str) -> bool:
    """
    Verify the attestation object from Apple WebAuthn
    """
    key_id_bytes = base64.b64decode(key_id)
    attest = base64.b64decode(attestation_object)
    nonce = generate_challenge(key_id).encode()
    config = AppleConfig(
        key_id=key_id_bytes,
        app_id=APP_ID,
        production=DEPLOYMENT_ENV == DeploymentEnvironment.PROD,
        root_ca=CERTIFICATE
    )
    attestation = Attestation(attest, nonce, config)

    try:
        attestation.verify()
        return True
    except PyAttestException:
        print(ResponseMessages.ERROR_VERIFYING_ATTESTATION.value)
        return False
    except Exception as e:
        print(ResponseMessages.ERROR_PARSING_ATTESTATION.value, e)
        return False
    
def generate_challenge(key_id: str) -> str:
    """ Generate a challenge for the given key_id """
    secret_key = os.environ.get('HMAC_SHA_KEY')
    
    # Generate deterministic bytes using HMAC of key_id
    seed_hmac = hmac.new(
        key=secret_key.encode('utf-8'),
        msg=key_id.encode('utf-8'),
        digestmod=hashlib.sha256
    )
    deterministic_bytes = seed_hmac.digest()
    
    message = f"{key_id}:{deterministic_bytes.hex()}".encode('utf-8')

    # Generate final HMAC
    hmac_obj = hmac.new(
        key=secret_key.encode('utf-8'),
        msg=message,
        digestmod=hashlib.sha256
    )
    challenge = hmac_obj.hexdigest()
    challenge_base64 = base64.b64encode(bytes.fromhex(challenge)).decode('utf-8')

    return challenge_base64