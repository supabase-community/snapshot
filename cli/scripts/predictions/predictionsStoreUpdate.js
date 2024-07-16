#!/usr/bin/env node
/* eslint-env node */
const axios = require('axios')
const args = require('minimist')(process.argv.slice(2))
const START_ENDPOINT =
  process.env.SNAPLET_API_HOSTNAME + '/admin/predictions.startUpdate'
const PROGRESS_ENDPOINT =
  process.env.SNAPLET_API_HOSTNAME + '/admin/predictions.pollUpdateProgress'
const MAX_RETRIES = 5
const WAIT_DURATION = 30000 // 30 seconds
const confidence = process.env.MODEL_CONFIDENCE
  ? parseFloat(process.env.MODEL_CONFIDENCE)
  : 0.65

async function startPrediction(type) {
  try {
    console.log('Starting prediction...', START_ENDPOINT)
    const response = await axios.post(
      START_ENDPOINT,
      { type, confidence },
      {
        responseType: 'json',
        headers: {
          authorization: `Bearer ${process.env.ADMIN_ACCESS_TOKEN}`,
        },
      }
    )
    const data = response.data?.result?.data
    if (!data) {
      console.log('Error starting prediction:', response)
      throw new Error('No predictionJobId returned from API')
    }
    return data
  } catch (error) {
    console.log('Error starting prediction:', error)
    throw error
  }
}

async function pollProgress(predictionJobIds) {
  let retries = 0
  while (retries < MAX_RETRIES) {
    console.log('+'.repeat(80))
    try {
      const res = await axios.post(
        PROGRESS_ENDPOINT,
        { predictionJobIds },
        {
          responseType: 'json',
          headers: {
            authorization: `Bearer ${process.env.ADMIN_ACCESS_TOKEN}`,
          },
        }
      )
      const results = res?.data?.result?.data
      for (const result of results) {
        const { predictionJobId, status, progress } = result

        console.log('-'.repeat(80))
        console.log(`Job Id: ${predictionJobId}`)
        console.log(`Status: ${status}`)
        console.log(`Progress: ${progress}`)
        console.log('-'.repeat(80))
      }
      const successList = results.filter((r) => r.status === 'COMPLETED')
      if (successList.length === predictionJobIds.length) {
        console.log(`Update process for all jobs are done.`)
        return
      } else {
        console.log(
          `${successList.length}/ ${predictionJobIds.length} jobs are done. Waiting for 60 seconds before polling again..`
        )
        console.log('+'.repeat(80))
        await new Promise((res) => setTimeout(res, WAIT_DURATION))
      }
    } catch (error) {
      retries++
      console.log(
        `API call failed. Retrying (${retries}/${MAX_RETRIES})...`,
        error
      )
      if (retries >= MAX_RETRIES) {
        console.log('Maximum retries reached. Exiting...')
        process.exit(1)
      }
      await new Promise((res) => setTimeout(res, 10000)) // Wait 10 seconds before retrying
    }
  }
}

;(async function predictionsStoreUpdate() {
  if (!process.env.ADMIN_ACCESS_TOKEN || !process.env.SNAPLET_API_HOSTNAME) {
    console.log('Missing environment variables. Exiting...')
    process.exit(1)
  }
  console.log(
    `Starting predictions store update... type: ${args.type}, confidence: ${confidence}`
  )
  let retryCount = 5
  let jobIds = []
  while (retryCount > 0) {
    retryCount -= 1
    const response = await startPrediction(args.type)
    if (!response.ready) {
      console.log(
        'Prediction endpoint is being started. Lets try again in 2 min.'
      )
      if (retryCount === 0) {
        console.log('Maximum retries reached. Exiting...')
        process.exit(1)
      }
      await new Promise((res) => setTimeout(res, 120000)) // Wait 2 min before retrying
    } else {
      jobIds.push(...response.predictionJobIds)
      console.log(
        'Prediction endpoints are ready. Jobs to process: ',
        jobIds.length
      )
      break
    }
  }
  console.log(`Prediction job started with ids: ${jobIds}`)
  if (jobIds.length === 0) {
    console.log('No jobs to run. Exiting...')
    process.exit(0)
  }
  await pollProgress(jobIds)
  console.log('All prediction jobs completed.')
})()
