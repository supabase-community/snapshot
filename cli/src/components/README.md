# Steps

Components display output or take input and are re-used in the CLI.

We have 3 types:
  1. Needs: Validate requirements
  2. Activities: Display side-effect state
  3. Inputs: User level interaction

## Needs

"Needs" are a way to validate and gather requirements for an action,
when the requirement is not met they provides a helpful and consistently formatted
error message designed for the user.

A need only tests a single requirement, and the requirements should be composed.
As an example: If you need a connection to a database, you also need a valid
connection string, so you'll have to specify both of those as "needs."

Some needs will also return the requirement that they're testing, so you can use
validating the requirement as a way to get things.

```js
import { needs } from '~/lib/needs.js'

// Example: I need a connection to the database
const connString = needs.databaseURL()
await needs.databaseConnection(connString)

// Example: I need to save project configuration
const paths = needs.projectPaths()
```

## Activities

Activities can take an indeterminate amount of time. They generally have 3 states:
Loading, Success and Failure.
