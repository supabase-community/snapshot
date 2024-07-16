import { createSqliteTestDatabase } from '~/testing/createSqliteDb.js'
import { withDbClient, execQueryNext } from '../client.js'
import { fetchSequences } from './fetchSequences.js'

test('should fetch primary key autoincrement sequence', async () => {
  const structure = `
    CREATE TABLE students (
      student_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(100) NOT NULL
    );
  `
  const connString = await createSqliteTestDatabase(structure)
  const sequences = await withDbClient(fetchSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual([
    {
      tableId: 'students',
      colId: 'student_id',
      name: 'students_student_id_seq', // The exact name might differ; adjust as necessary
      start: 1,
      min: 1,
      max: 2147483647,
      current: 1,
      interval: 1,
    },
  ])
})

test('should fetch rowid sequence on table wihtout primary key', async () => {
  const structure = `
    CREATE TABLE students (
      name VARCHAR(100) NOT NULL
    );
  `
  const connString = await createSqliteTestDatabase(structure)
  const sequences = await withDbClient(fetchSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual(
    expect.arrayContaining([
      {
        tableId: 'students',
        colId: 'rowid',
        name: 'students_rowid_seq', // The exact name might differ; adjust as necessary
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
    INSERT INTO students (name) VALUES ('John Doe'), ('Jane Smith');
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
        tableId: 'students',
        colId: 'rowid',
        name: 'students_rowid_seq', // The exact name might differ; adjust as necessary
        start: 1,
        min: 1,
        max: 2147483647,
        current: 3,
        interval: 1,
      },
    ])
  )
})
