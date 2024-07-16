# Snaplet CLI

## Building

The CLI is built in three phases:

1. Build the code: `node ./scripts/BuildCode.mjs`
2. Package the Node.js binary and code into an executable: `node ./scripts/buildPackage.mjs`
3. Create and upload a Docker container: `node ./scripts/buildContainer.mjs`

## Contributing

### Code Structure

The organizational structure of the CLI is `snaplet <object> <action>`, we use this common structure to organize our code through colocation, our thoughts, and provide a consistent experience to the users.

As an example, the `snaplet config pull` command has the following directory structure:
```
  commands/
    config/
      actions/
        pullAction.ts
      configCommand.ts
```

We prefix `Command` and `Action` to the end of the filename so that they're easily searchable by name.

### Debugging

The `yarn dev` command will build and run the CLI with the appropriate envars.

Example: `yarn dev config pull`

## Release process

The broad steps for releasing the Snaplet CLI are the following:

1. Increment `version` in `cli/package.json`
2. Commit and merge this change to `main`
3. A GitHub Action will build, package, upload and release the version.


### Triggering a release

Increment the `version` string in `cli/package.json`, commit and push it to the main branch.

### GitHub Action

The "cli.release" GitHub Action will determine if the new version exists in production.

It does this by querying Snaplet API (`api.snaplet.dev/admin/releaseVersion.findByVersion`), and determining if `package.json::version` does not exist in our production database.

### Build, package, upload, and release

Snaplet CLI is transpiled and polyfilled with `yarn build`.

It's then packaged into an executable: That means the Node.js binary and the JavaScript bytecode are combined into a single file. We do this so that user's don't need to have Node.js installed on their system to enjoy the benefits of Snaplet. We use the excellent [pkg](https://github.com/vercel/pkg) project to facilitate this.

The CLI binaries for Mac, Linux and Window are uploaded to S3.

The new version is pushed to production by mutating Snaplet API (`api.snaplet.dev/admin/releaseVersion.create`).

### Release Channels

We segment our CLI user's into channels. By default a new release is set to `ALPHA`, and in order to make a release public set the channel to `BETA` by manually modifying the production database.

We'll improve this by introducing an admin interface.

### Subsetting

#### Local:
Create subset config using the cli:
```terminal
SNAPLET_TARGET_DATABASE_URL='postgresql://postgres:postgres@localhost:5432/snaplet_development'  yarn dev:raw subset config (Or snaplet config subset)
```

Have a look at subsetting.json, you can edit it to suit your needs. For snaplet_development it might look like this:
```json
{
  "enabled": true,
  "initial_targets": [
    {
      "table": "public.Organization",
      "row_limit": 6
    }
  ],
  "keep_disconnected_tables": true,
  "excluded_tables": [
    "pgboss.archive",
    "pgboss.job",
    "pgboss.schedule",
    "pgboss.version",
    "pgboss.archive",
    "pgboss.job",
    "pgboss.schedule",
    "pgboss.version"
  ]
}
```

Capture a local snapshot with subsetting:
```terminal
SNAPLET_SOURCE_DATABASE_URL='postgresql://postgres:postgres@localhost:5432/snaplet_development' yarn dev:raw snapshot capture
```

Restore a local snapshot with subsetting:
```terminal
SNAPLET_TARGET_DATABASE_URL='postgresql://postgres:postgres@localhost:5432/snaplet_development' yarn dev:raw snapshot restore
```
