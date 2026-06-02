import os

from temporalio.client import Client

from .temporal_cloud_auth import get_api_key


async def connect() -> Client:
    """Connect to Temporal using the same env-driven config as the Lambda worker.

    Reads TEMPORAL_ADDRESS / TEMPORAL_NAMESPACE from the environment (mise base env →
    localhost dev server; mise.<env>.toml → Temporal Cloud). When TEMPORAL_API_KEY_PARAM
    is set, the API key is fetched from SSM Parameter Store and TLS is enabled automatically
    (Temporal Cloud); otherwise the connection is plaintext for local development.
    """
    address = os.environ.get("TEMPORAL_ADDRESS", "localhost:7233")
    namespace = os.environ.get("TEMPORAL_NAMESPACE", "default")
    return await Client.connect(
        address,
        namespace=namespace,
        # None locally → no TLS; set for Cloud → SDK enables TLS automatically.
        api_key=get_api_key(),
    )
