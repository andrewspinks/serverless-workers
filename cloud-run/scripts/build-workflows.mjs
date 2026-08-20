import { mkdir, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { bundleWorkflowCode } from "@temporalio/worker";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);

async function run() {
  const outputDirectory = join(scriptDirectory, "..", "dist");
  const { code } = await bundleWorkflowCode({
    workflowsPath: require.resolve("../src/workflows.ts"),
  });

  await mkdir(outputDirectory, { recursive: true });
  const outputPath = join(outputDirectory, "workflow-bundle.js");
  await writeFile(outputPath, code);
  console.log(`Workflow bundle written to ${outputPath}`);
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
