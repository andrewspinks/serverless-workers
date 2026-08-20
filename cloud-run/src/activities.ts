import { log } from "@temporalio/activity";

export async function greet(name: string): Promise<string> {
  log.info("Greeting requested", { name });
  return `Hello, ${name}! (from Cloud Run)`;
}
