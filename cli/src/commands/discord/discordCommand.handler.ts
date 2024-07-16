import open from 'open'

const SNAPLET_DISCORD_CHAT_URL = 'https://app.snaplet.dev/chat'

export async function handler() {
  await open(SNAPLET_DISCORD_CHAT_URL)
  console.log(
    `Attempting to open browser window to: ${SNAPLET_DISCORD_CHAT_URL}`
  )
}
