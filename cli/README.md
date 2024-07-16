# Snaplet CLI

Seed your development database with accurate data. [Read the docs](https://docs.snaplet.dev)

# Running e2e tests locally

We use `snaplet dev` during development, but for e2e tests the latency is a bit high.
In order to run the tests against your local database, do the following:

```terminal
SNAPLET_TARGET_DATABASE_URL=postgresql://postgres@localhost/snaplet_development yarn snaplet ss r --latest
DATABASE_URL=postgresql://postgres@localhost/snaplet_development yarn dev
```

Then in another terminal:
```
yarn workspace cli test:debug ./cli/e2e/<path/to/test>
```


