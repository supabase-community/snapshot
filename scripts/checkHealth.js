const MAX_TIMEOUT = 30 * 1000
const HEALTH_URL = 'https://api.snaplet.dev/health'

async function checkHealth() {
  console.log('Checking health...')
  const startTime = Date.now()

  // eslint-disable-next-line no-constant-condition
  while (true) {
    try {
      const response = await fetch(HEALTH_URL)

      if (response.ok) {
        const responseBody = await response.text()

        if (responseBody === 'OK') {
          console.log('Health check passed')
          break
        }
      }

      await new Promise((resolve) => setTimeout(resolve, 5000))
    } catch (error) {
      await new Promise((resolve) => setTimeout(resolve, 5000))
    }

    const elapsedTime = Date.now() - startTime
    if (elapsedTime >= MAX_TIMEOUT) {
      throw new Error('Timeout reached')
    }
  }
}

module.exports = checkHealth
