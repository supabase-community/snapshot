import { getSystemPath, safeReadJson, saveJson } from '@snaplet/sdk/cli'
import got from 'got-cjs'
import path from 'path'

import { SNAPLET_API_HOSTNAME, RUNTIME_INSTALL_DETAILS } from './constants.js'

type State = {
  lastCheckedAt: string
  latestVersion: string
}

function getStatePath() {
  const systemPath = getSystemPath()
  return path.join(systemPath, 'state.json')
}

export function makeInstallCommand(tag: string): string {
  let command = ''
  if (RUNTIME_INSTALL_DETAILS.isGlobal) {
    if (RUNTIME_INSTALL_DETAILS.type === 'yarn') {
      command = `yarn global add snaplet@${tag}`
    } else if (RUNTIME_INSTALL_DETAILS.type === 'npm') {
      command = `npm i -g snaplet@${tag}`
    } else if (RUNTIME_INSTALL_DETAILS.type === 'bash') {
      command = `snaplet upgrade`
    }
  } else {
    if (RUNTIME_INSTALL_DETAILS.type === 'yarn') {
      command = `yarn add snaplet@${tag}`
    } else {
      command = `npm i snaplet@${tag}`
    }
  }
  return command
}

export async function getState() {
  const statePath = getStatePath()
  const state = await safeReadJson<State>(statePath)
  return state
}

async function saveState(state: State) {
  const statePath = getStatePath()
  await saveJson(statePath, state)
}

export async function refreshState(options?: { timeout: number }) {
  const apiHostname = `${SNAPLET_API_HOSTNAME}/version`
  const { version: latestVersion } = await got(apiHostname, {
    timeout: { request: options?.timeout },
  }).json<{
    version: string
  }>()

  const state = {
    latestVersion,
    lastCheckedAt: new Date().toISOString(),
  }
  await saveState(state)

  return state
}
