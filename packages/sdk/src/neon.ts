// from https://neon.tech/docs/introduction/regions#available-regions
const regions = [
  // note: this is the order displayed on the web app.
  { id: 'aws-us-east-2', name: 'US East (Ohio)' },
  { id: 'aws-us-east-1', name: 'US East (N. Virginia)' },
  { id: 'aws-us-west-2', name: 'US West (Oregon)' },
  { id: 'aws-eu-central-1', name: 'Europe (Frankfurt)' },
  { id: 'aws-ap-southeast-1', name: 'Asia Pacific (Singapore)' },
] as const

// from https://neon.tech/docs/reference/compatibility#postgresql-versions
const pgVersions = [14, 15] as const

const DEFAULT_REGION = 'aws-us-east-1' as const

const DEFAULT_PG_VERSION = 15 as const

const DEFAULT_MAIN_BRANCH = 'snappy_main' as const

export const neon = {
  DEFAULT_MAIN_BRANCH,
  DEFAULT_REGION,
  DEFAULT_PG_VERSION,
  regions,
  pgVersions,
}
