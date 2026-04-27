import { bundleWorkflowCode } from '@temporalio/worker';
import * as fs from 'fs';
import * as path from 'path';

async function build(): Promise<void> {
  console.log('Bundling workflow code...');
  const { code } = await bundleWorkflowCode({
    workflowsPath: require.resolve('./workflows'),
  });
  const outDir = path.resolve(__dirname, '..', 'dist');
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'workflow-bundle.js'), code);
  console.log('dist/workflow-bundle.js written');
}

build().catch((err) => {
  console.error(err);
  process.exit(1);
});
