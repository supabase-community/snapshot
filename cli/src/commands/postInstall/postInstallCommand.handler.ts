import { captureEvent } from '~/lib/telemetry.js'

export async function handler() {
  await captureEvent('$command:postInstall:start')
  await captureEvent('$command:postInstall:end')
}
