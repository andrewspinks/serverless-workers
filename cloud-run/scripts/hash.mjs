import { createHash } from "node:crypto";

const value = process.argv[2];
const requestedLength = Number.parseInt(process.argv[3] ?? "64", 10);

if (
  !value ||
  !Number.isSafeInteger(requestedLength) ||
  requestedLength < 1 ||
  requestedLength > 64
) {
  throw new Error("Usage: hash.mjs VALUE [LENGTH]");
}

console.log(
  createHash("sha256").update(value).digest("hex").slice(0, requestedLength),
);
