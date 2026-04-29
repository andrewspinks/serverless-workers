// esbuild bundles @temporalio/worker but leaves native require.resolve() calls untouched.
// At Lambda runtime the relative paths resolve against /var/task/handler.js and fail.
// These modules are never invoked in Lambda (workflow bundling and threaded VMs are
// replaced by pre-built workflowBundle + the lambda-worker execution model).

import { readFileSync, writeFileSync } from 'fs';

const bundlePath = 'dist/handler.js';
let content = readFileSync(bundlePath, 'utf8');
let patched = false;

const patches = [
  {
    // bundler.js: defaultWorkflowInterceptorModules — only used by WorkflowCodeBundler (webpack)
    pattern: /require\.resolve\(["']\.\.\/workflow-log-interceptor["']\)/g,
    replacement: '"__workflow_log_interceptor_not_used_in_lambda__"',
    label: 'workflow-log-interceptor',
  },
  {
    // threaded-vm.js: WorkerThreadClient spawning — lambda-worker uses a single-threaded model
    pattern: /require\.resolve\(["']\.\/workflow-worker-thread["']\)/g,
    replacement: '"__workflow_worker_thread_not_used_in_lambda__"',
    label: 'workflow-worker-thread',
  },
];

for (const { pattern, replacement, label } of patches) {
  const next = content.replace(pattern, replacement);
  if (next === content) {
    console.warn(`patch-bundle: pattern not found for ${label} — SDK internals may have changed`);
  } else {
    content = next;
    patched = true;
    console.log(`patch-bundle: patched require.resolve(${label})`);
  }
}

if (patched) {
  writeFileSync(bundlePath, content);
}
