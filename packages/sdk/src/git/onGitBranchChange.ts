import fs from 'fs'
import execa from 'execa'
import path from 'path'

// Function to get the current Git branch
const getCurrentGitBranch = async (): Promise<string> => {
  try {
    const result = await execa('git', ['symbolic-ref', '--short', 'HEAD'], {
      cwd: process.env.SNAPLET_CWD,
    })
    return result.stdout.trim()
  } catch (err) {
    console.log('Error getting current branch:', err)
    throw err
  }
}

export async function* onGitBranchChange(): AsyncIterable<string> {
  let currentBranch: string | null = null

  // Get the initial branch
  try {
    currentBranch = await getCurrentGitBranch()
    yield currentBranch
  } catch (err) {
    console.log('Error getting initial branch:', err)
    return
  }

  // Find the '.git' folder location
  const result = await execa('git', ['rev-parse', '--git-dir'], {
    cwd: process.env.SNAPLET_CWD,
  })
  const gitFolderPath = result.stdout.trim()
  if (!gitFolderPath) {
    console.log('Could not find the .git folder.')
    return
  }
  const gitHeadPath = path.join(process.env.SNAPLET_CWD!, gitFolderPath, 'HEAD')

  async function waitForChange(): Promise<void> {
    return new Promise((resolve) => {
      const watcher = fs.watch(gitHeadPath, (eventType) => {
        if (eventType === 'change' || eventType === 'rename') {
          watcher.close() // Close the watcher once the event is captured
          resolve()
        }
      })
    })
  }

  // eslint-disable-next-line no-constant-condition
  while (true) {
    try {
      const newBranch = await getCurrentGitBranch()
      if (newBranch !== currentBranch) {
        currentBranch = newBranch
        yield newBranch
      }
    } catch (err) {
      console.log('Error getting updated branch:', err)
    }
    await waitForChange()
  }
}
