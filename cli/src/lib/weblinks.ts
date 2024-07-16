import open from 'open'

const SNAPLET_DOCUMENTATION_URL = 'https://docs.snaplet.dev/?utm_source=cli'

const openUrl = async (url: string, quiet = false) => {
  if (!quiet) {
    console.log(`Attempting to open browser window to: ${url}`)
  }
  await open(SNAPLET_DOCUMENTATION_URL)
}

export const openSnapletDevelopmentDocumentation = async () => {
  await openUrl(SNAPLET_DOCUMENTATION_URL)
}
