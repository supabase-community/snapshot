# Snaplet Snapshots

## Introduction

Snapshots are database snapshots captured from an existing database that you can access (typically production). Snapshots can be subset (reduced in size), and the source data can be transformed to meet your requirements (for example, obfuscating personally identifiable information). Snapshots are restored into a database as part of your workflow, whether that's your local coding environment or CI/CD.

## Documentation

The Snaplet snapshot documentation can be found [here](https://snaplet-snapshot.netlify.app/snapshot/getting-started/overview).

## Getting started

To get started with Snaplet snapshots, follow these steps:

1. Configure your Snaplet CLI by running the following command:

  ```terminal
  npx @snaplet/snapshot setup
  ```

2. To capture a new snapshot, you will have to define your source database with the `SNAPLET_SOURCE_DATABASE_URL` environment variable. Capture a new snapshot by running the following command:

  ```terminal
 SNAPLET_SOURCE_DATABASE_URL='' npx @snaplet/snapshot snapshot capture
  ```

> Note: Replace `SNAPLET_SOURCE_DATABASE_URL` with your source database URL. Example: `postgresql://USER:PASSWORD@REMOTE_DB_HOST:PORT/DB_NAME`

3. List all available snapshots by running the following command:

  ```terminal
  npx @snaplet/snapshot snapshot ls
  ```

4. Restore a snapshot to your source database by running the following command:

  ```terminal
  npx @snaplet/snapshot snapshot restore
  ```

That's it! You're now ready to use Snaplet snapshots in your workflow.

For more information, refer to the [Snaplet snapshot documentation](https://snaplet-snapshot.netlify.app/snapshot/getting-started/overview).


# Contribution

## Setup

First, you'll need PostgreSQL and brotli installed and running on your machine. If you're using macOS and Homebrew:

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

Make sure you have `yarn` version above 3.5.0 installed. On macOS, `yarn` comes with `corepack`:
```
corepack enable
yarn --version
3.5.0
```

In the root directory, run:
```
yarn install
yarn build
```

## Test CLI

Create a new directory and set up the database (usually the local development database):
```
mkdir test
cd test
node ../cli/dist/index.js setup
```

Capture a new snapshot:
```
SNAPLET_SOURCE_DATABASE_URL=postgresql://USER:PASSWORD@REMOTE_DB_HOST:PORT/DB_NAME node ../cli/dist/index.js ss capture
```

List snapshots:
```
node ../cli/dist/index.js ss ls
NAME                          STATUS     CREATED     SIZE       TAGS    SRC
ss-fluffy-microwave-143354    SUCCESS    just now    15.3 MB            💻

Found 1 snapshot
```

Restore to your source database (specified during `setup`):
```
node ../cli/dist/index.js ss restore
```



## [Release process](https://www.loom.com/share/9561c964bc454065b19dd779393995c8)

1. Make a PR that updates the version in the `cli/package.json` file.

2. Once merged into main, add a git tag with the version number specified in step 1. For example, if the version is `0.93.4`, run:
```terminal
git tag v0.93.4
```

3. Push the tag to the remote repository:
```terminal
git push --tags
```

4. A draft release will be created on GitHub. Once the npm package is ready, edit the release notes and publish the release.

[Here](https://www.loom.com/share/9561c964bc454065b19dd779393995c8) is a video showing our current release process for the Snaplet Snapshot CLI.



