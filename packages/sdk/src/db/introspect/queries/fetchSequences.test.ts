import { createTestDb } from '../../../testing.js'
import { execQueryNext, withDbClient } from '../../client.js'
import { fetchSequences } from './fetchSequences.js'

test('should fetch basic sequences', async () => {
  const structure = `
    CREATE SEQUENCE public.seq_example INCREMENT 1 START 1;
  `
  const connString = await createTestDb(structure)
  const sequences = await withDbClient(fetchSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual([
    {
      schema: 'public',
      name: 'seq_example',
      start: 1, // Adjust according to actual fetched format (string or number)
      min: 1, // Adjust according to actual fetched format (string or number)
      max: 9223372036854776000, // Default max value for bigint sequene
      current: 1, // Current value might be '1' if not used yt
      interval: 1,
    },
  ])
})

test('should fetch sequences used by tables', async () => {
  const structure = `
    CREATE TABLE public.students (
      student_id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL
    );
    CREATE TABLE public.courses (
      course_id SERIAL PRIMARY KEY,
      title VARCHAR(100) NOT NULL
    );
    -- Assuming SERIAL creates a sequence named 'students_student_id_seq' and 'courses_course_id_seq'
  `
  const connString = await createTestDb(structure)
  const sequences = await withDbClient(fetchSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual(
    expect.arrayContaining([
      {
        schema: 'public',
        name: 'students_student_id_seq', // The exact name might differ; adjust as necessary
        start: 1,
        min: 1,
        max: 2147483647,
        current: 1,
        interval: 1,
      },
      {
        schema: 'public',
        name: 'courses_course_id_seq', // The exact name might differ; adjust as necessary
        start: 1,
        min: 1,
        max: 2147483647,
        current: 1,
        interval: 1,
      },
    ])
  )
  await execQueryNext(
    `
    INSERT INTO public.students (name) VALUES ('John Doe'), ('Jane Smith');
    INSERT INTO public.courses (title) VALUES ('Mathematics'), ('Science');
    -- This will increment the sequences associated with student_id and course_id
  `,
    connString
  )
  expect(
    await withDbClient(fetchSequences, {
      connString: connString.toString(),
    })
  ).toEqual(
    expect.arrayContaining([
      {
        schema: 'public',
        name: 'students_student_id_seq', // The exact name might differ; adjust as necessary
        start: 1,
        min: 1,
        max: 2147483647,
        current: 3,
        interval: 1,
      },
      {
        schema: 'public',
        name: 'courses_course_id_seq', // The exact name might differ; adjust as necessary
        start: 1,
        min: 1,
        max: 2147483647,
        current: 3,
        interval: 1,
      },
    ])
  )
})

test('should handle empty result when no accessible sequences', async () => {
  const structure = ``
  const connString = await createTestDb(structure)
  const sequences = await withDbClient(fetchSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual([])
})

test('should fetch multiple sequences', async () => {
  const structure = `
    CREATE SEQUENCE public.seq_example1 INCREMENT 1 START 1;
    CREATE SEQUENCE public.seq_example2 INCREMENT 1 START 50;
  `
  const connString = await createTestDb(structure)
  const sequences = await withDbClient(fetchSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual(
    expect.arrayContaining([
      {
        current: 1,
        interval: 1,
        max: 9223372036854776000,
        min: 1,
        start: 1,
        name: 'seq_example1',
        schema: 'public',
      },
      {
        current: 50,
        interval: 1,
        max: 9223372036854776000,
        min: 1,
        start: 50,
        name: 'seq_example2',
        schema: 'public',
      },
    ])
  )
})

test('should fetch multiple sequences across schemas', async () => {
  const structure = `
    CREATE SCHEMA extra;
    CREATE SEQUENCE public.seq_public INCREMENT BY 1 START WITH 1;
    CREATE SEQUENCE extra.seq_extra INCREMENT BY 1 START WITH 1;
  `
  const connString = await createTestDb(structure)
  const sequences = await withDbClient(fetchSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual(
    expect.arrayContaining([
      {
        schema: 'public',
        name: 'seq_public',
        start: 1,
        min: 1,
        max: 9223372036854776000,
        current: 1,
        interval: 1,
      },
      {
        schema: 'extra',
        name: 'seq_extra',
        start: 1,
        min: 1,
        max: 9223372036854776000,
        current: 1,
        interval: 1,
      },
    ])
  )
})
