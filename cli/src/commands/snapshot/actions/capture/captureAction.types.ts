import type { TransformModes } from '@snaplet/sdk/cli'

export interface CommandOptions {
  destinationPath?: string
  message?: string
  subsetPath?: string
  tags: string[]
  transformMode?: TransformModes
  uniqueName?: string
}
