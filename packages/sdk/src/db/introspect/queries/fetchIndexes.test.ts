import { createTestDb } from '../../../testing.js'
import { withDbClient } from '../../client.js'
import { fetchIndexes } from './fetchIndexes.js'

test('should get basics primary keys indexes', async () => {
  const structure = `
    CREATE TABLE "Courses" (
        "CourseID" SERIAL PRIMARY KEY,
        "CourseName" VARCHAR(255) NOT NULL
    );
    CREATE TABLE "Students" (
        "StudentID" SERIAL PRIMARY KEY,
        "FirstName" VARCHAR(255) NOT NULL,
        "LastName" VARCHAR(255) NOT NULL
    );
  `
  const connString = await createTestDb(structure)
  const primaryKeys = await withDbClient(fetchIndexes, {
    connString: connString.toString(),
  })
  expect(primaryKeys).toEqual([
    {
      definition:
        'CREATE UNIQUE INDEX "Courses_pkey" ON public."Courses" USING btree ("CourseID")',
      index: 'Courses_pkey',
      indexColumns: expect.arrayContaining(['CourseID']),
      schema: 'public',
      table: 'Courses',
      type: 'btree',
    },
    {
      definition:
        'CREATE UNIQUE INDEX "Students_pkey" ON public."Students" USING btree ("StudentID")',
      index: 'Students_pkey',
      indexColumns: expect.arrayContaining(['StudentID']),
      schema: 'public',
      table: 'Students',
      type: 'btree',
    },
  ])
})

test('should get composite primary keys indexes', async () => {
  const structure = `
    CREATE TABLE "Courses" (
        "CourseID" SERIAL PRIMARY KEY,
        "CourseName" VARCHAR(255) NOT NULL
    );
    CREATE TABLE "Students" (
        "StudentID" SERIAL PRIMARY KEY,
        "FirstName" VARCHAR(255) NOT NULL,
        "LastName" VARCHAR(255) NOT NULL
    );
    CREATE TABLE "Enrollments" (
        "CourseID" INT NOT NULL,
        "StudentID" INT NOT NULL,
        PRIMARY KEY ("CourseID", "StudentID"),
        FOREIGN KEY ("CourseID") REFERENCES "Courses"("CourseID"),
        FOREIGN KEY ("StudentID") REFERENCES "Students"("StudentID")
    );
    CREATE TABLE "Grades" (
        "CourseID" INT NOT NULL,
        "StudentID" INT NOT NULL,
        "ExamName" VARCHAR(255) NOT NULL,
        "Grade" FLOAT NOT NULL,
        PRIMARY KEY ("CourseID", "StudentID", "ExamName"),
        FOREIGN KEY ("CourseID", "StudentID") REFERENCES "Enrollments"("CourseID", "StudentID")
    );
  `
  const connString = await createTestDb(structure)
  const primaryKeys = await withDbClient(fetchIndexes, {
    connString: connString.toString(),
  })
  expect(primaryKeys).toEqual([
    {
      definition:
        'CREATE UNIQUE INDEX "Courses_pkey" ON public."Courses" USING btree ("CourseID")',
      index: 'Courses_pkey',
      indexColumns: expect.arrayContaining(['CourseID']),
      schema: 'public',
      table: 'Courses',
      type: 'btree',
    },
    {
      definition:
        'CREATE UNIQUE INDEX "Enrollments_pkey" ON public."Enrollments" USING btree ("CourseID", "StudentID")',
      index: 'Enrollments_pkey',
      indexColumns: expect.arrayContaining(['CourseID', 'StudentID']),
      schema: 'public',
      table: 'Enrollments',
      type: 'btree',
    },
    {
      definition:
        'CREATE UNIQUE INDEX "Grades_pkey" ON public."Grades" USING btree ("CourseID", "StudentID", "ExamName")',
      index: 'Grades_pkey',
      indexColumns: expect.arrayContaining([
        'CourseID',
        'StudentID',
        'ExamName',
      ]),
      schema: 'public',
      table: 'Grades',
      type: 'btree',
    },
    {
      definition:
        'CREATE UNIQUE INDEX "Students_pkey" ON public."Students" USING btree ("StudentID")',
      index: 'Students_pkey',
      indexColumns: expect.arrayContaining(['StudentID']),
      schema: 'public',
      table: 'Students',
      type: 'btree',
    },
  ])
})

test('should get indexes on different schemas', async () => {
  const structure = `
    CREATE SCHEMA private;
    CREATE TABLE public."Courses" (
        "CourseID" SERIAL PRIMARY KEY,
        "CourseName" VARCHAR(255) NOT NULL
    );
    CREATE TABLE private."Students" (
        "StudentID" SERIAL PRIMARY KEY,
        "FirstName" VARCHAR(255) NOT NULL,
        "LastName" VARCHAR(255) NOT NULL
    );
  `
  const connString = await createTestDb(structure)
  const primaryKeys = await withDbClient(fetchIndexes, {
    connString: connString.toString(),
  })
  expect(primaryKeys).toEqual(
    expect.arrayContaining([
      {
        definition:
          'CREATE UNIQUE INDEX "Students_pkey" ON private."Students" USING btree ("StudentID")',
        index: 'Students_pkey',
        indexColumns: expect.arrayContaining(['StudentID']),
        schema: 'private',
        table: 'Students',
        type: 'btree',
      },
      {
        definition:
          'CREATE UNIQUE INDEX "Courses_pkey" ON public."Courses" USING btree ("CourseID")',
        index: 'Courses_pkey',
        indexColumns: expect.arrayContaining(['CourseID']),
        schema: 'public',
        table: 'Courses',
        type: 'btree',
      },
    ])
  )
})
