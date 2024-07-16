import { createSqliteTestDatabase } from '~/testing/createSqliteDb.js'
import { withDbClient } from './client.js'
import { introspectSqliteDatabase } from './introspectSqliteDatabase.js'
import { introspectedSqliteToDataModel } from './introspectedSqliteToDataModel.js'

test('should return empty array if no relations', async () => {
  const structure = `
    CREATE TABLE "Courses" (
      "CourseID" INTEGER PRIMARY KEY AUTOINCREMENT,
      "CourseName" TEXT NOT NULL
    );
    CREATE TABLE "Students" (
        "StudentID" INTEGER PRIMARY KEY AUTOINCREMENT,
        "FirstName" TEXT NOT NULL,
        "LastName" TEXT NOT NULL
    );
  `
  const connString = await createSqliteTestDatabase(structure)
  const introspection = await withDbClient(introspectSqliteDatabase, {
    connString: connString.toString(),
  })
  const dataModel = await introspectedSqliteToDataModel(introspection)
  expect(dataModel).toEqual({
    enums: {},
    models: {
      Courses: {
        fields: [
          {
            columnName: 'CourseID',
            hasDefaultValue: false,
            id: 'Courses.CourseID',
            isGenerated: false,
            isId: true,
            isList: false,
            isRequired: false,
            kind: 'scalar',
            name: 'CourseID',
            sequence: {
              current: 1,
              identifier: 'Courses_CourseID_seq',
              increment: 1,
              start: 1,
            },
            type: 'integer',
          },
          {
            columnName: 'CourseName',
            hasDefaultValue: false,
            id: 'Courses.CourseName',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'CourseName',
            sequence: false,
            type: 'text',
          },
        ],
        id: 'Courses',
        tableName: 'Courses',
        uniqueConstraints: [
          {
            columns: ['CourseID'],
            dirty: false,
            name: 'Courses_pkey',
            table: 'Courses',
            tableId: 'Courses',
          },
        ],
      },
      Students: {
        fields: [
          {
            columnName: 'StudentID',
            hasDefaultValue: false,
            id: 'Students.StudentID',
            isGenerated: false,
            isId: true,
            isList: false,
            isRequired: false,
            kind: 'scalar',
            name: 'StudentID',
            sequence: {
              current: 1,
              identifier: 'Students_StudentID_seq',
              increment: 1,
              start: 1,
            },
            type: 'integer',
          },
          {
            columnName: 'FirstName',
            hasDefaultValue: false,
            id: 'Students.FirstName',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'FirstName',
            sequence: false,
            type: 'text',
          },
          {
            columnName: 'LastName',
            hasDefaultValue: false,
            id: 'Students.LastName',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'LastName',
            sequence: false,
            type: 'text',
          },
        ],
        id: 'Students',
        tableName: 'Students',
        uniqueConstraints: [
          {
            columns: ['StudentID'],
            dirty: false,
            name: 'Students_pkey',
            table: 'Students',
            tableId: 'Students',
          },
        ],
      },
    },
  })
})

test('should return relations', async () => {
  const structure = `
    CREATE TABLE "Courses" (
      "CourseID" INTEGER PRIMARY KEY AUTOINCREMENT,
      "CourseName" TEXT NOT NULL
    );
    CREATE TABLE "Students" (
        "StudentID" INTEGER PRIMARY KEY AUTOINCREMENT,
        "FirstName" TEXT NOT NULL,
        "LastName" TEXT NOT NULL
    );
    CREATE TABLE "Enrollments" (
        "EnrollmentID" INTEGER PRIMARY KEY AUTOINCREMENT,
        "StudentID" INTEGER NOT NULL,
        "CourseID" INTEGER NOT NULL,
        FOREIGN KEY ("StudentID") REFERENCES "Students" ("StudentID"),
        FOREIGN KEY ("CourseID") REFERENCES "Courses" ("CourseID")
    );
  `
  const connString = await createSqliteTestDatabase(structure)
  const introspection = await withDbClient(introspectSqliteDatabase, {
    connString: connString.toString(),
  })
  const dataModel = await introspectedSqliteToDataModel(introspection)
  expect(dataModel).toEqual({
    enums: {},
    models: {
      Courses: {
        fields: [
          {
            columnName: 'CourseID',
            hasDefaultValue: false,
            id: 'Courses.CourseID',
            isGenerated: false,
            isId: true,
            isList: false,
            isRequired: false,
            kind: 'scalar',
            name: 'CourseID',
            sequence: {
              current: 1,
              identifier: 'Courses_CourseID_seq',
              increment: 1,
              start: 1,
            },
            type: 'integer',
          },
          {
            columnName: 'CourseName',
            hasDefaultValue: false,
            id: 'Courses.CourseName',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'CourseName',
            sequence: false,
            type: 'text',
          },
          {
            hasDefaultValue: false,
            isGenerated: false,
            isId: false,
            isList: true,
            isRequired: false,
            kind: 'object',
            name: 'Enrollments',
            relationFromFields: [],
            relationName: 'EnrollmentsToCourses',
            relationToFields: [],
            sequence: false,
            type: 'Enrollments',
          },
        ],
        id: 'Courses',
        tableName: 'Courses',
        uniqueConstraints: [
          {
            columns: ['CourseID'],
            dirty: false,
            name: 'Courses_pkey',
            table: 'Courses',
            tableId: 'Courses',
          },
        ],
      },
      Enrollments: {
        fields: [
          {
            columnName: 'EnrollmentID',
            hasDefaultValue: false,
            id: 'Enrollments.EnrollmentID',
            isGenerated: false,
            isId: true,
            isList: false,
            isRequired: false,
            kind: 'scalar',
            name: 'EnrollmentID',
            sequence: {
              current: 1,
              identifier: 'Enrollments_EnrollmentID_seq',
              increment: 1,
              start: 1,
            },
            type: 'integer',
          },
          {
            columnName: 'StudentID',
            hasDefaultValue: false,
            id: 'Enrollments.StudentID',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'StudentID',
            sequence: false,
            type: 'integer',
          },
          {
            columnName: 'CourseID',
            hasDefaultValue: false,
            id: 'Enrollments.CourseID',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'CourseID',
            sequence: false,
            type: 'integer',
          },
          {
            hasDefaultValue: false,
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'object',
            name: 'Courses',
            relationFromFields: ['CourseID'],
            relationName: 'EnrollmentsToCourses',
            relationToFields: ['CourseID'],
            sequence: false,
            type: 'Courses',
          },
          {
            hasDefaultValue: false,
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'object',
            name: 'Students',
            relationFromFields: ['StudentID'],
            relationName: 'EnrollmentsToStudents',
            relationToFields: ['StudentID'],
            sequence: false,
            type: 'Students',
          },
        ],
        id: 'Enrollments',
        tableName: 'Enrollments',
        uniqueConstraints: [
          {
            columns: ['EnrollmentID'],
            dirty: false,
            name: 'Enrollments_pkey',
            table: 'Enrollments',
            tableId: 'Enrollments',
          },
        ],
      },
      Students: {
        fields: [
          {
            columnName: 'StudentID',
            hasDefaultValue: false,
            id: 'Students.StudentID',
            isGenerated: false,
            isId: true,
            isList: false,
            isRequired: false,
            kind: 'scalar',
            name: 'StudentID',
            sequence: {
              current: 1,
              identifier: 'Students_StudentID_seq',
              increment: 1,
              start: 1,
            },
            type: 'integer',
          },
          {
            columnName: 'FirstName',
            hasDefaultValue: false,
            id: 'Students.FirstName',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'FirstName',
            sequence: false,
            type: 'text',
          },
          {
            columnName: 'LastName',
            hasDefaultValue: false,
            id: 'Students.LastName',
            isGenerated: false,
            isId: false,
            isList: false,
            isRequired: true,
            kind: 'scalar',
            name: 'LastName',
            sequence: false,
            type: 'text',
          },
          {
            hasDefaultValue: false,
            isGenerated: false,
            isId: false,
            isList: true,
            isRequired: false,
            kind: 'object',
            name: 'Enrollments',
            relationFromFields: [],
            relationName: 'EnrollmentsToStudents',
            relationToFields: [],
            sequence: false,
            type: 'Enrollments',
          },
        ],
        id: 'Students',
        tableName: 'Students',
        uniqueConstraints: [
          {
            columns: ['StudentID'],
            dirty: false,
            name: 'Students_pkey',
            table: 'Students',
            tableId: 'Students',
          },
        ],
      },
    },
  })
})
