# Copycat release process

## Requirements
All the steps below assume you have cloned the copycat repo (https://github.com/snaplet/copycat) and and have the following permissions:
* copycat write npm repository permissions
* github copycat project permissions
* Retool dashboard permission
* Crisp permission
* Discord Release channel permission
* snaplet github repository permission

## Non-major releases
### Publish
If it is a non-major release (i.e. no breaking changes), in your clone of the copycat repo, simply run `yarn release` with the version bump type (`minor` or `patch`) in . For example:

```sh
yarn release minor
```

### Add release to changelog
Go to the copycat repository: https://github.com/snaplet/copycat

Click on "Releases", find your release and add changelog notes. You can use previous releases in the changelog as a template for the general structure we use.

## Major releases
Major releases cause breaking changes in snapshots on snaplet cloud, and so we first have to give users notice, then schedule the release.

### Stage 1: Notice and preview release

#### 1. Publish copycat releases

Run the following in your clone of the copycat repo:

```sh
yarn release major
```

It will publish two releases to npm:
* The preview release (e.g. 4.0.0-preview.0): this release will contain a preview of the release for the user to try out by using `import { copycat } from '@snaplet/copycat/next'`
* The major release (e.g. 4.0.0): the release with the latest breaking changes included

#### 2. Draft a new release with warning

Then you want to go onto the copycat repository: https://github.com/snaplet/copycat

Click on "Releases" and find the release tag for the major release (e.g. 4.0.0). In the message, mention the breaking change.

Something like:

```
## ⚠ BREAKING CHANGES
`copycat.float()` method has been rewritten: previously, output values would stay close to the `min` value give. With this release, output values will distribute more evenly across the (min, max) range of values.

This means that inputs for `copycat.float()` will now map to a different output. It is still deterministic - the same input will always map to the same output. It is just that after the upgrade the corresponding output for each input will have changed.
```

#### 3. Use the new preview release in snaplet

For example, if the 4.0.0-preview.0 was the published preview release, run the following in the snaplet repo:

```
yarn up @copycat/snaplet@4.0.0-preview.0
```

Create a PR for the change.

#### 4. Release the change
Once the upgrade PR is merged, follow the usual release process https://github.com/snaplet/snaplet?tab=readme-ov-file#release-process

Bump the version to the next __patch__ semver version.

For the changelog notes, you can use this template:

```
## Snaplet Changelog for Release v<VERSION>

**⚠ `@snaplet/copycat` BREAKING CHANGE NOTICE**

**What is changing?**
<DESCRIBE CHANGE HERE>

**When will the change happen?**
We are planning on releasing the change on **<DATE>** at <TIME> UTC

**Who will be affected?**
You might be impacted by this change if you use snapshots, and <DESCRIBE CASES WHEN THIS CHANGE WILL AFFECT USERS>

**Why is it changing?**
<ADD CONTEXT HERE>

**How to prepare:**
To preview the impact of this change, you can modify your `copycat` import in your configuration.
From: `import { copycat } from '@snaplet/copycat'`
To: `import { copycat } from '@snaplet/copycat/next'`.

**Need More Time?**
If the scheduled update time doesn’t suit your schedule, please let us know. We are sorry for any inconvenience this may cause and are here to assist with a smoother transition. Thank you for your attention to this matter.
```

#### 5. Message possibles impacted snaplet users

First you want to find a list of the possibly affected users, to do so we query the config of actives projects in production that use some specific copycat methods and get the list of all the possibly impacted users and get their project owners mail addresses.

There is a little tool on retool to help you do that: https://snaplet.retool.com/apps/6ee23bcc-8216-11ee-9e05-6ff5f7b0ca45/Snaplet copycat breaking change release

You can use it to select the mails of the owners of organizations with projects impacted by your change.

You also must provide a "segment" name that we will use on crisp to send a targeted mail to those users.

Once it's done, download the csv for it by clicking the "download" button on the table in retool dashboard.

Then we must import thoses as "contact" with their new segment in crisp.

To do this, on Crisp platform, head over the "Contact" section

choose "Actions" then "Import contacts".

Drop the downloaded csv in the file place and wait for the import to finish.

Then, we want to create a "mailing campaign" for all users with this tag on.

To do so, head over the "Campaign" section.

Click on the "New campaign" button and choose "Instantaneous campaign"

To configure the targets, choose: "advanced filters" then "new filter" then "Segment", "equal to <your-segment>"

Use this template:

```
Subject
Upcoming Changes to Snaplet's @snaplet/copycat

Hi there, <NAME> from Snaplet here.

I'd like to inform you about an important update we have scheduled, which will impact how we transform and generate data using [copycat](https://github.com/snaplet/copycat).

<USE SAME CONTENT AS CHANGELOG UPDATE HERE, EXCEPT WITHOUT THE BREAKING CHANGE NOTICE HEADING>

Thank you for your attention to this matter.

Best regards,
<NAME>
```

Choose "send me a test email" to make sure the email is what you desire, then you can send it to the users.

### Stage 2: Switch to major release

At the day and time that the major release was scheduled for, we now need to upgrade to this version:

#### 1. Use the major release in snaplet

For example, if the 4.0.0 was the published major release, run the following in the snaplet repo:

```
yarn up @copycat/snaplet@4.0.0
```

Create a PR for the change. There may be tests that need updating because of the breaking change.

#### 2. Release the change
Once the upgrade PR is merged, follow the usual release process https://github.com/snaplet/snaplet?tab=readme-ov-file#release-process

Bump the version to the next __minor__ semver version.

For the changelog notes, you can reuse the copy from the copycat changelog added at for the major release earlier at https://github.com/snaplet/copycat/releases

```
## Snaplet Changelog for Release v<VERSION>

**⚠ `@snaplet/copycat` BREAKING CHANGE**
<COPY FROM COPYCAT CHANGELOG FOR MAJOR RELEASE>
```