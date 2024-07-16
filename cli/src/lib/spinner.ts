import ora from 'ora'
import ms from 'ms'
import c from 'ansi-colors'

/** @deprecated use `activity` instead. */
export const spinner = ora

/**
 * Use an activity indicator when using I/O (database, network, or disk)
 * to let the user know that something is happening.
 *
 * Always specify the object that you're interacting with
 * ("Project file", "Database connection", "Source database") and the
 * task that you're trying to achieve ("Connecting...", "Writing...", "Generating...")
 *
 * Use the `done`, `info` or `fail` methods to update that status of the activity.
 */
export const activity = (objectName: string, taskName: string) => {
  const startTime = Date.now()
  const elapsedTimeText = () => {
    return c.dim(`[${ms(Date.now() - startTime)}]`)
  }
  const title = `${objectName}: ${taskName}`

  const act = ora({ stream: process.stderr }).start(title)
  return {
    /** Removes activity indicator */
    done() {
      act.stop()
    },
    /** Shows pass message */
    pass(text?: string) {
      act.succeed(
        text ? `${objectName}: ${text}` : title + ' ' + elapsedTimeText()
      )
    },
    info(text: string) {
      act.info(`${objectName}: ${text}`)
    },
    fail(text?: string) {
      act.info(`${objectName}: ${text ?? taskName}`)
    },
  }
}
