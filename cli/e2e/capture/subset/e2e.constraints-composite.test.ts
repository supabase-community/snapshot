import { execQueryNext } from '@snaplet/sdk/cli'
import {
  createTestDb,
  createTestCapturePath,
  createTestProjectDirV2,
  runSnapletCLI,
  checkConstraints,
} from '../../../src/testing/index.js'
import fsExtra from 'fs-extra'

vi.setConfig({
  testTimeout: 10 * 60 * 1000,
})

test('capturing and restoring database with composite FK and composite FK', async () => {
  const structure = `
    CREATE TABLE "Authors" (
        "AuthorID" SERIAL PRIMARY KEY,
        "FirstName" VARCHAR(255) NOT NULL,
        "LastName" VARCHAR(255) NOT NULL
    );

    CREATE TABLE "Books" (
        "BookID" SERIAL PRIMARY KEY,
        "Title" VARCHAR(255) NOT NULL,
        "AuthorID" INT NOT NULL,
        FOREIGN KEY ("AuthorID") REFERENCES "Authors"("AuthorID"),
        UNIQUE ("BookID", "AuthorID")
    );

    CREATE TABLE "BookEditions" (
        "EditionID" SERIAL PRIMARY KEY,
        "BookID" INT NOT NULL,
        "AuthorID" INT NOT NULL,
        "EditionName" VARCHAR(255) NOT NULL,
        "PublicationYear" INT NOT NULL,
        FOREIGN KEY ("BookID", "AuthorID") REFERENCES "Books"("BookID", "AuthorID")
    );

    CREATE TABLE "BookSales" (
        "EditionID" INT NOT NULL,
        "SaleDate" DATE NOT NULL,
        "QuantitySold" INT NOT NULL,
        PRIMARY KEY ("EditionID", "SaleDate"),
        FOREIGN KEY ("EditionID") REFERENCES "BookEditions"("EditionID")
    );
  `
  const sourceConnectionString = await createTestDb(structure)
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const insertDataScript = `
  INSERT INTO "Authors" ("FirstName", "LastName")
  VALUES ('George', 'Orwell'),
        ('Aldous', 'Huxley'),
        ('Ray', 'Bradbury');

  INSERT INTO "Books" ("Title", "AuthorID")
  VALUES ('1984', 1),
        ('Brave New World', 2),
        ('Fahrenheit 451', 3);

  INSERT INTO "BookEditions" ("BookID", "AuthorID", "EditionName", "PublicationYear")
  VALUES (1, 1, 'First Edition', 1949),
        (2, 2, 'First Edition', 1932),
        (3, 3, 'First Edition', 1953),
        (1, 1, 'Second Edition', 1934);

  INSERT INTO "BookSales" ("EditionID", "SaleDate", "QuantitySold")
  VALUES (1, '2023-04-01', 10),
        (2, '2023-04-01', 12),
        (2, '2023-04-02', 12),
        (1, '2023-04-02', 12),
        (3, '2023-04-03', 15);
  `
  await execQueryNext(insertDataScript, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: true,
      targets: [
        {
          table: 'public.Books',
          where: \`"Books"."Title" = '1984'\`,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)

  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const bookEditions = await execQueryNext(
    `SELECT * FROM "BookEditions"`,
    targetConnectionString
  )
  const bookSales = await execQueryNext(
    `SELECT * FROM "BookSales"`,
    targetConnectionString
  )
  expect(bookEditions.rowCount).toEqual(2)
  expect(bookEditions.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        BookID: 1,
        AuthorID: 1,
        EditionName: 'First Edition',
        PublicationYear: 1949,
      }),
      expect.objectContaining({
        BookID: 1,
        AuthorID: 1,
        EditionName: 'Second Edition',
        PublicationYear: 1934,
      }),
    ])
  )
  expect(bookSales.rowCount).toEqual(2)
  expect(bookSales.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        EditionID: 1,
        QuantitySold: 10,
      }),
      expect.objectContaining({
        EditionID: 1,
        QuantitySold: 12,
      }),
    ])
  )
})

test('capturing and restoring database where a table composite PK is also FK', async () => {
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
  `
  const sourceConnectionString = await createTestDb(structure)
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const insertDataScript = `
      INSERT INTO "Courses" ("CourseName")
      VALUES ('Mathematics'),
            ('Physics'),
            ('Chemistry');

      INSERT INTO "Students" ("FirstName", "LastName")
      VALUES ('John', 'Doe'),
            ('Jane', 'Smith'),
            ('Alice', 'Johnson');

      INSERT INTO "Enrollments" ("CourseID", "StudentID")
      VALUES (1, 1),
            (1, 2),
            (2, 3),
            (1, 3);
  `
  await execQueryNext(insertDataScript, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.Courses',
          where: \`"Courses"."CourseName" = 'Physics'\`,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )
  const courses = await execQueryNext(
    `SELECT * FROM "Courses"`,
    targetConnectionString
  )
  const students = await execQueryNext(
    `SELECT * FROM "Students"`,
    targetConnectionString
  )
  const enrollments = await execQueryNext(
    `SELECT * FROM "Enrollments"`,
    targetConnectionString
  )

  expect(courses.rowCount).toEqual(1)
  expect(courses.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        CourseID: 2,
        CourseName: 'Physics',
      }),
    ])
  )

  expect(students.rowCount).toEqual(1)
  expect(students.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        StudentID: 3,
        FirstName: 'Alice',
        LastName: 'Johnson',
      }),
    ])
  )

  expect(enrollments.rowCount).toEqual(1)
  expect(enrollments.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        CourseID: 2,
        StudentID: 3,
      }),
    ])
  )
})

test('capturing and restoring database where a table composite FK referencing another composite PK', async () => {
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
  const sourceConnectionString = await createTestDb(structure)
  const targetConnectionString = await createTestDb()
  const paths = await createTestProjectDirV2()
  const insertDataScript = `
      INSERT INTO "Courses" ("CourseName")
      VALUES ('Mathematics'),
            ('Physics'),
            ('Chemistry');

      INSERT INTO "Students" ("FirstName", "LastName")
      VALUES ('John', 'Doe'),
            ('Jane', 'Smith'),
            ('Alice', 'Johnson');

      INSERT INTO "Enrollments" ("CourseID", "StudentID")
      VALUES (1, 1),
            (1, 2),
            (2, 3),
            (1, 3);

      INSERT INTO "Grades" ("CourseID", "StudentID", "ExamName", "Grade")
      VALUES (1, 1, 'Midterm', 85.0),
            (1, 2, 'Midterm', 90.0),
            (1, 3, 'Midterm', 88.0),
            (2, 3, 'Midterm', 50.0);
  `
  await execQueryNext(insertDataScript, sourceConnectionString)

  const configContent = `
  import { copycat } from "@snaplet/copycat";
  import { defineConfig } from "snaplet";

  export default defineConfig({
    subset: {
      enabled: true,

      keepDisconnectedTables: false,
      targets: [
        {
          table: 'public.Courses',
          where: \`"Courses"."CourseName" = 'Physics'\`,
        },
      ],
    },
  })`
  await fsExtra.writeFile(paths.snapletConfig, configContent)
  const ssPath = createTestCapturePath()

  await runSnapletCLI(
    ['snapshot', 'capture', ssPath.name],
    {
      SNAPLET_SOURCE_DATABASE_URL: sourceConnectionString.toString(),
    },
    paths
  )

  await runSnapletCLI(
    ['snapshot restore', ssPath.name],
    {
      SNAPLET_TARGET_DATABASE_URL: targetConnectionString.toString(),
    },
    paths
  )

  await checkConstraints(
    sourceConnectionString.toString(),
    targetConnectionString.toString()
  )

  const courses = await execQueryNext(
    `SELECT * FROM "Courses"`,
    targetConnectionString
  )
  const students = await execQueryNext(
    `SELECT * FROM "Students"`,
    targetConnectionString
  )
  const enrollments = await execQueryNext(
    `SELECT * FROM "Enrollments"`,
    targetConnectionString
  )
  const grades = await execQueryNext(
    `SELECT * FROM "Grades"`,
    targetConnectionString
  )
  expect(courses.rowCount).toEqual(1)
  expect(courses.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        CourseID: 2,
        CourseName: 'Physics',
      }),
    ])
  )
  expect(students.rowCount).toEqual(1)
  expect(students.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        StudentID: 3,
        FirstName: 'Alice',
        LastName: 'Johnson',
      }),
    ])
  )

  expect(enrollments.rowCount).toEqual(1)
  expect(enrollments.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        CourseID: 2,
        StudentID: 3,
      }),
    ])
  )

  expect(grades.rowCount).toEqual(1)
  expect(grades.rows).toEqual(
    expect.arrayContaining([
      expect.objectContaining({
        CourseID: 2,
        StudentID: 3,
        ExamName: 'Midterm',
        Grade: 50.0,
      }),
    ])
  )
})
