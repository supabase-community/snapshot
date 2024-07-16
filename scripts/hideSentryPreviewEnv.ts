import kebabCase from 'lodash/kebabCase'

const SENTRY_SNAPLET_PROJECTS = ['api', 'web', 'cli']
const SENTRY_API_BASE_URL = 'https://snaplet.sentry.io/api/0/projects/snaplet'

// Hide all environments who might have been attached related to the preview on sentry
async function main() {
  const sentryEnvName = kebabCase(process.env.STAGE).slice(0, 63)
  const authToken = `Bearer ${process.env.SNAPLET_SENTRY_AUTH_TOKEN}`
  const requests = SENTRY_SNAPLET_PROJECTS.map(async (projectName) => {
    const req = await fetch(
      `${SENTRY_API_BASE_URL}/${projectName}/environments/${sentryEnvName}/`,
      {
        method: 'PUT',
        headers: {
          accept: 'application/json; charset=utf-8',
          'content-type': 'application/json',
          Authorization: authToken,
        },
        body: JSON.stringify({
          name: sentryEnvName,
          isHidden: true,
        }),
      }
    )
    return req.json()
  })
  const results = await Promise.allSettled(requests)
  console.log(results)
}

void main()
