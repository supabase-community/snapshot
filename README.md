# Snaplet

Everything you see here is everything we have: our codebase is a monorepo that is
split into "sides:"

1. `cli`: What developers install on their computers to interact with the API and their databases.
2. `packages`: Shared code between "sides."

## Installation

We use yarn v3 as our package manager, it's great for those of us who have not-so-great Internet connections, because it stores a global cache of the packages on your local machine.

```terminal
yarn install
```

Besides that you have all the credentials that you require in `.env.defaults`. These are development only credentials. We do not share production credentials.

## Getting started

First, you'll need PostgreSQL and brotli installed and running on your machine. If you're using OSX and homebrew:

```terminal
brew install postgresql@15
brew services start postgresql@15
brew install libpq
brew install brotli

# if you do not yet have a `postgres` role with these role attributes
psql postgres -c 'create role postgres WITH SUPERUSER CREATEDB CREATEROLE LOGIN'
```

Next, you'll need the production Snaplet CLI up and running so that you can bootstrap your dev environment - using Snaplet itself to restore a database snapshot:

1. Get invited to "Snaplet" on "Snaplet Cloud": Once you have CLI installed, you'll need an invite link for [Snaplet Cloud](app.snaplet.dev) If you do not have one yet, ask for one in #product on Discord.
2. Join "Snaplet" on Snaplet Cloud: Visit the invite link and follow the onboarding steps, you should land on the dashboard page, and be part of the Snaplet team on Snaplet Cloud.
3. Login the Snaplet CLI: Run `yarn snaplet auth setup` in the root of the monorepo and follow the steps.
4. Restore a snapshot: Run `yarn snaplet snapshot restore`, in the root of the monorepo.

At this point you'll have a bootstrapped dev environment, and are ready to start it up!

```terminal
yarn dev
```

We run the API and WEB sides via pm2, when you make changes the code is rebuilt, and the changes are reloaded.

Whilst working on the CLI you can use the `yarn dev` command to see test your latest changes. It uses the last created `Database` as a starting point:

```terminal
cd cli
yarn dev ls
```

Note: If you make changes in the packages/sdk folder you have to rebuild the sdk to use it in the api:

```
cd api
yarn workspace @snaplet/sdk build
```

If you want to use a specific database use the `SNAPLET_PROJECT_ID` envar:

```
cd cli
SNAPLET_PROJECT_ID=xxx-xxx yarn dev ls
```

## [Release process](https://www.loom.com/share/9561c964bc454065b19dd779393995c8)

Here's a video showing our current release process for snaplet CLI, `@snaplet/seed` and `@snaplet/sdk`: https://www.loom.com/share/9561c964bc454065b19dd779393995c8

## Deploy process
For API and web, changes in PRs are deployed automatically when they land on the `main` branch.

You can inspect the logs for the deploy on papertrail: https://my.papertrailapp.com/groups/26388041/events?q=program%3Adeploy

# Testing and debugging

## Command Line Interface (CLI) - End-to-End (E2E) Tests

To execute all end-to-end tests in the CLI package, follow these steps:
```
cd cli
yarn test:e2e
```
To run a specific test, use the following command:
```
test:debug e2e/mytest.test.ts
```
This will execute the test without a timeout in a single thread, and you can use the debugger.

## Using the Debugger in Visual Studio Code (VSCode)
Follow these steps to use the debugger in VSCode:

1. Enable the debugger by Pressing `Cmd+Shift+P` and search for `Debug: Toggle auto attach` and select `smart`
2. Open a new `Javascript Debug Terminal` by pressing `Cmd+Shift+P` and search for `Terminal: Create New Integrated Terminal` and select `Javascript Debug Terminal`'
3. Add a breakpoint in the code you want to debug
4. Run the test you want to debug with `yarn test:debug e2e/mytest.test.ts`

**_NOTE:_** If you want to see the debug logs when running the test you add add the `DEBUG` env var to the test command like this: `DEBUG=snaplet:* yarn test:debug e2e/mytest.test.ts`

# Monorepo remaining tasks
- [ ] Solid ESBuild configuration (mostly autofixable)
- [ ] Usage of imports map instead of TypeScript paths aliases


# Contribution

## Setup

First, you'll need PostgreSQL and brotli installed and running on your machine. If you're using OSX and homebrew:

```terminal
brew install postgresql@15
brew services start postgresql@15
brew install libpq
brew install brotli

# if you do not yet have a `postgres` role with these role attributes
psql postgres -c 'create role postgres WITH SUPERUSER CREATEDB CREATEROLE LOGIN'
```
Make sure you have Node.js 20 or above installed:
```
node --version
v20.15.1
```

Make sure you have `yarn` version above 3.5.0 installed, on MacOS `yarn` comes with `corepack`:
```
corepack enable
yarn --version
3.5.0
```

In root directory run:
```
yarn install
yarn build
```

## Test cli

Create new directory and setup database:
```
mkdir test
cd test
node ../cli/dist/index.js setup
```

Capture a new snapshot:
```
SNAPLET_SOURCE_DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres node ../cli/dist/index.js ss capture
```

List snapshots:
```
node ../cli/dist/index.js ss ls
NAME                          STATUS     CREATED     SIZE       TAGS    SRC
ss-fluffy-microwave-143354    SUCCESS    just now    15.3 MB            💻

Found 1 snapshot
```

Restore to another database:
```
SNAPLET_TARGET_DATABASE_URL=postgresql://postgres:postgres@localhost:54322/copy node ../cli/dist/index.js ss restore
```