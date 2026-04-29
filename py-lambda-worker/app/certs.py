import os

import boto3
from temporalio.service import TLSConfig

_cached: TLSConfig | None = None
_fetched: bool = False


def get_tls_certs() -> TLSConfig | None:
    """Fetches mTLS client cert and key from Secrets Manager.

    Returns None if TEMPORAL_TLS_CERT_ARN / TEMPORAL_TLS_KEY_ARN are not set.
    Called synchronously at cold start from the run_worker configure callback.
    """
    global _cached, _fetched
    if _fetched:
        return _cached

    cert_arn = os.environ.get("TEMPORAL_TLS_CERT_ARN")
    key_arn = os.environ.get("TEMPORAL_TLS_KEY_ARN")
    if not cert_arn or not key_arn:
        _fetched = True
        return None

    sm = boto3.client("secretsmanager")
    cert = sm.get_secret_value(SecretId=cert_arn)["SecretString"].encode()
    key = sm.get_secret_value(SecretId=key_arn)["SecretString"].encode()
    _cached = TLSConfig(client_cert=cert, client_private_key=key)
    _fetched = True
    return _cached
