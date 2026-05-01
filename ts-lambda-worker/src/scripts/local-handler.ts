import { readFileSync } from "fs";
import { handler } from "../handler";

const [eventPath, envPath] = process.argv.slice(2);
if (!eventPath) {
  console.error(
    "usage: ts-node src/scripts/local-handler.ts <event.json> [<local-env.json>]",
  );
  process.exit(1);
}

if (envPath) {
  const envFile = JSON.parse(readFileSync(envPath, "utf8"));
  const overrides = envFile.WorkerFunction ?? {};
  for (const [key, value] of Object.entries(overrides)) {
    process.env[key] = String(value);
  }
}

const event = JSON.parse(readFileSync(eventPath, "utf8"));
const context = {
  awsRequestId: "local",
  functionName: "WorkerFunction",
  functionVersion: "$LATEST",
  invokedFunctionArn: "local",
  memoryLimitInMB: "256",
  logGroupName: "local",
  logStreamName: "local",
  callbackWaitsForEmptyEventLoop: false,
  getRemainingTimeInMillis: () => 60_000,
  done: () => {},
  fail: () => {},
  succeed: () => {},
} as unknown as Parameters<typeof handler>[1];

handler(event, context).catch((err) => {
  console.error(err);
  process.exit(1);
});
