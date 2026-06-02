import os

import boto3

_cached: str | None = None
_fetched: bool = False


def get_api_key() -> str | None:
    """Fetches the Temporal Cloud API key from SSM Parameter Store (SecureString).

    Returns None if TEMPORAL_API_KEY_PARAM is not set. Called synchronously at cold
    start from the run_worker configure callback; result is cached for warm invocations.
    """
    global _cached, _fetched
    if _fetched:
        return _cached

    param_name = os.environ.get("TEMPORAL_API_KEY_PARAM")
    if not param_name:
        _fetched = True
        return None

    ssm = boto3.client("ssm")
    _cached = ssm.get_parameter(Name=param_name, WithDecryption=True)["Parameter"]["Value"]
    _fetched = True
    return _cached
