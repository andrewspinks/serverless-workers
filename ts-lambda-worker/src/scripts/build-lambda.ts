import { spawnSync, SpawnSyncReturns } from "child_process";
import {
  copyFileSync,
  mkdirSync,
  readdirSync,
  rmSync,
  statSync,
} from "fs";
import { join } from "path";

const ROOT = join(__dirname, "..", "..");
const OUT = join(ROOT, "dist-lambda");
const ALLOWED_PLATFORM = "x86_64-unknown-linux-gnu";

function run(command: string, args: string[], cwd: string = ROOT): void {
  const result: SpawnSyncReturns<Buffer> = spawnSync(command, args, {
    cwd,
    stdio: "inherit",
  });
  if (result.status !== 0) {
    throw new Error(
      `${command} ${args.join(" ")} failed (status ${result.status})`,
    );
  }
}

rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });

run("pnpm", ["install", "--frozen-lockfile"]);
run("pnpm", ["run", "build:bundle"]);
run("pnpm", ["exec", "tsc", "--build", "--force"]);

for (const file of readdirSync(join(ROOT, "dist"))) {
  if (file.endsWith(".js")) {
    copyFileSync(join(ROOT, "dist", file), join(OUT, file));
  }
}
for (const file of ["package.json", "temporal.toml", "client.pem", "client.key"]) {
  copyFileSync(join(ROOT, file), join(OUT, file));
}

run("npm", ["install", "--omit=dev", "--ignore-scripts"], OUT);

const releases = join(OUT, "node_modules", "@temporalio", "core-bridge", "releases");
for (const platform of readdirSync(releases)) {
  if (platform === ALLOWED_PLATFORM) continue;
  const target = join(releases, platform);
  if (statSync(target).isDirectory()) {
    rmSync(target, { recursive: true, force: true });
  }
}

console.log(`Lambda artifact built at ${OUT}`);
