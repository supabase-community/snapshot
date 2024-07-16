import { createTestDb, createTestRole } from '../../../testing.js'
import { withDbClient } from '../../client.js'
import { fetchAuthorizedSequences } from './fetchAuthorizedSequences.js'

test('should fetch basic sequences', async () => {
  const structure = `
    CREATE TABLE public."SequenceTest" (id integer NOT NULL);
    CREATE SEQUENCE
      IF NOT EXISTS
      public."SequenceTest_id_seq"
      AS integer
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1
      OWNED BY "SequenceTest"."id";
  `
  const connString = await createTestDb(structure)
  const sequences = await withDbClient(fetchAuthorizedSequences, {
    connString: connString.toString(),
  })
  expect(sequences).toEqual([
    {
      column: 'id',
      schema: 'public',
      sequence: 'SequenceTest_id_seq',
      table: 'SequenceTest',
    },
  ])
})

test('should not fetch sequences on schemas the user does not have access to', async () => {
  const structure = `
    CREATE TABLE public."SequenceTest" (id integer NOT NULL);
    CREATE SEQUENCE
      IF NOT EXISTS
      public."SequenceTest_id_seq"
      AS integer
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1
      OWNED BY public."SequenceTest"."id";
    CREATE TABLE public."OtherTest" (id integer NOT NULL);
    CREATE SEQUENCE
      IF NOT EXISTS
      public."OtherTest_id_seq"
      AS integer
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1
      OWNED BY public."OtherTest"."id";
    CREATE SCHEMA private;
    CREATE TABLE private."TableInPrivateSchema" (id integer NOT NULL);
    CREATE SEQUENCE
      IF NOT EXISTS
      private."TableInPrivateSchema_id_seq"
      AS integer
      START WITH 1
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1
      OWNED BY private."TableInPrivateSchema"."id";
  `
  const connString = await createTestDb(structure)
  const testRoleConnString = await createTestRole(connString)
  const sequences = await withDbClient(fetchAuthorizedSequences, {
    connString: testRoleConnString.toString(),
  })
  expect(sequences).toEqual([
    {
      column: 'id',
      schema: 'public',
      sequence: 'OtherTest_id_seq',
      table: 'OtherTest',
    },
    {
      column: 'id',
      schema: 'public',
      sequence: 'SequenceTest_id_seq',
      table: 'SequenceTest',
    },
  ])
})
