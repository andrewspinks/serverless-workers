import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import type { TLSConfig } from '@temporalio/worker';

const client = new SecretsManagerClient({});
let cached: TLSConfig | undefined;

async function getSecret(arn: string): Promise<Buffer> {
  const { SecretString } = await client.send(new GetSecretValueCommand({ SecretId: arn }));
  if (!SecretString) throw new Error(`Secret ${arn} has no string value`);
  return Buffer.from(SecretString);
}

/**
 * Fetches mTLS client cert and key from Secrets Manager.
 * Returns undefined if TEMPORAL_TLS_CERT_ARN / TEMPORAL_TLS_KEY_ARN are not set.
 */
export async function getTLSCerts(): Promise<TLSConfig | undefined> {
  const certArn = process.env['TEMPORAL_TLS_CERT_ARN'];
  const keyArn = process.env['TEMPORAL_TLS_KEY_ARN'];
  if (!certArn || !keyArn) return undefined;
  if (cached) return cached;

  const [crt, key] = await Promise.all([getSecret(certArn), getSecret(keyArn)]);
  cached = { clientCertPair: { crt, key } };
  return cached;
}
