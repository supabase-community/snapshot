import { ConnectionString, encodeConnectionString } from './ConnectionString.js'
import { findWorkingDbConnString } from './node.js'

test('throws with incorrect fallback databases', async () => {
  try {
    await findWorkingDbConnString(
      'postgresql://postgres:postgres@localhost/bad_database',
      ['bad_postgres', 'bad_template_1']
    )
  } catch (e) {
    expect((e as Error).name).toEqual('DB_CONNECTION_AUTH')
  }
})

test('correct credentials with correct fallback database', async () => {
  try {
    const cs = await findWorkingDbConnString(
      'postgresql://postgres:postgres@localhost/bad_database',
      ['postgres']
    )
    expect(cs).toEqual('postgresql://postgres:postgres@localhost:5432/postgres')
  } catch (e) {
    // NOTE: We fail here on purpose. You need to create a "postgres" database.
    expect(false).toEqual(true)
  }
})

describe('ConnectionString', () => {
  test('adds connection string defaults', () => {
    expect(
      new ConnectionString('postgresql://user:pass@localhost').toString()
    ).toBe('postgresql://user:pass@localhost:5432/postgres')

    expect(
      new ConnectionString('postgresql://user:pass@localhost:5432').toString()
    ).toBe('postgresql://user:pass@localhost:5432/postgres')

    expect(
      new ConnectionString('postgresql://user:pass@localhost:5432/').toString()
    ).toBe('postgresql://user:pass@localhost:5432/')

    expect(
      new ConnectionString(
        'postgresql://user:pass@localhost/db?a=b&c=d'
      ).toString()
    ).toBe('postgresql://user:pass@localhost:5432/db?a=b&c=d')

    expect(new ConnectionString('postgresql:///db').toString()).toBe(
      'postgresql://postgres@localhost:5432/db'
    )
  })

  test('accepts ConnectionString instances', () => {
    expect(new ConnectionString(ConnectionString.default).toString()).toEqual(
      ConnectionString.default.toString()
    )
  })

  describe('fromObject', () => {
    test('parsing', () => {
      expect(
        ConnectionString.fromObject({
          username: 'u',
          password: 'p',
          hostname: 'h',
          port: 1111,
          database: 'db',
          search: 'a=b&c=d',
        })
      )
    })

    test('adds connection object defaults', () => {
      expect(ConnectionString.fromObject({}).toString()).toEqual(
        ConnectionString.default.toString()
      )

      expect(
        ConnectionString.fromObject({
          port: 1337,
        }).port
      ).toEqual(1337)
    })
  })

  describe('isValid', () => {
    test('strings with missing segments', () => {
      expect(new ConnectionString('').validationErrors).toBe('INVALID')
      expect(new ConnectionString('postgresql://').validationErrors).toBeNull()
      expect(
        new ConnectionString('postgresql:///db').validationErrors
      ).toBeNull()
      expect(
        new ConnectionString('postgresql://localhost').validationErrors
      ).toBeNull()
      expect(
        new ConnectionString('postgresql://user:pass@localhost')
          .validationErrors
      ).toBeNull()
      expect(
        new ConnectionString('postgresql://localhost/db').validationErrors
      ).toBeNull()
      expect(
        new ConnectionString('postgresql://user@localhost').validationErrors
      ).toBeNull()
      expect(
        new ConnectionString('postgresql://user@localhost/db').validationErrors
      ).toBeNull()
    })

    test('malformed segments', () => {
      expect(
        new ConnectionString('postgresql://%').validationErrors
      ).toBeDefined()
    })

    test('strings with query params', () => {
      expect(
        new ConnectionString('postgresql://user@localhost/db?a=b&c=d')
          .validationErrors
      ).toBeNull()
    })

    test.each([
      'postgresql://pos!gres:sna@p*y(123@locahost/db',
      // string containing spaces
      'postgresql://post gres:pass wo rd@locahost/db',
      // database name can encoded
      'postgresql://postgres:password@locahost/db?[with] spaces',
    ])('strings containing special characters can be encoded.', (str) => {
      let connString = new ConnectionString(str)

      // should fail
      expect(connString.validationErrors).not.toBeNull()

      const encoded = encodeConnectionString(connString).toString()
      // we should automatically encode the connection string
      connString = new ConnectionString(encoded)

      expect(connString.validationErrors).toBeNull()

      const reencoded = encodeConnectionString(connString).toString()
      connString = new ConnectionString(reencoded)

      expect(reencoded).toBe(encoded)
    })

    test('strings with url symbols in segments', () => {
      expect(
        new ConnectionString(
          'postgresql://peterp:pa@@word@example.org:2345/mlf%40prod?ssl=true'
        ).validationErrors
      ).toBe('UNSERIALIZABLE')

      expect(
        new ConnectionString(
          'postgresql://peterp:pass123!@#@db.snaplet.io:5432/my_db/trial'
        ).validationErrors
      ).toBe('INVALID')

      expect(
        new ConnectionString(
          'postgresql://peter:p:ssword@example.org:2345/mlf%40prod?ssl=true'
        ).validationErrors
      ).toBe('UNSERIALIZABLE')
      expect(
        new ConnectionString(
          'postgresql://peter:p&ssword@example.org:2345/mlf%40prod?ssl=true'
        ).validationErrors
      ).toBe('INVALID_URI_SEGMENT')
    })

    // context(justinvdm, 2 March 2022): https://www.rfc-editor.org/rfc/rfc3986#section-2
    test('non-url special chars in segments that may be left unencoded', () => {
      '-_.!~*()'.split('').forEach((char) => {
        expect(
          new ConnectionString(`postgresql://user:pa${char}@localhost/db`)
            .validationErrors
        ).toBeNull()
      })
    })

    test('encoded reserved chars', () => {
      ;[
        '%21',
        '%27',
        '%28',
        '%29',
        '%2A',
        '%2D',
        '%5F',
        '%2E',
        '%21',
        '%7E',
        '%2A',
        '%28',
        '%29',
      ].forEach((char) => {
        expect(
          new ConnectionString(`postgresql://user:pa${char}@localhost/db`)
            .validationErrors
        ).toBeNull()
      })
    })

    // context(justinvdm, 2 March 2022): https://www.rfc-editor.org/rfc/rfc3986#section-2
    test('non-url special chars in segments that must be encoded', () => {
      // context(justinvdm, 2 March 2022): note that this is not the full set of chars that need to be encoded
      '^<>&;|'.split('').forEach((char) => {
        expect(
          new ConnectionString(`postgresql://user:pa${char}@localhost/db`)
            .validationErrors
        ).toBeDefined()
      })
    })

    test('strings with url symbols that have been encoded', () => {
      expect(
        new ConnectionString(
          'postgresql://arluene:Tiy%7CdxGFk2@pg-db-provision.cm0mkpwj8arx.eu-central-1.rds.amazonaws.com:5432/azure_goose'
        ).validationErrors
      ).toBeNull()
    })

    test('strings with different protocols', () => {
      expect(new ConnectionString('postgresql://').validationErrors).toBeNull()
      expect(new ConnectionString('postgres://').validationErrors).toBeNull()
      expect(new ConnectionString('pg://').validationErrors).toBeNull()

      expect(new ConnectionString('potgresql://').validationErrors).toBe(
        'UNRECOGNIZED_PROTOCOL'
      )
      expect(new ConnectionString('pgsql://').validationErrors).toBe(
        'UNRECOGNIZED_PROTOCOL'
      )
    })

    test('strings with uppercase hostnames', () => {
      expect(
        new ConnectionString(
          'postgresql://USER:PASSWORD@LOCALHOST:5432/DATABASE_NAME'
        ).validationErrors
      ).toBeNull()
    })
  })

  describe('setDatabase', () => {
    test('changes db name', () => {
      expect(
        new ConnectionString('postgresql://user@localhost:5432/db')
          .setDatabase('winrar')
          .toString()
      ).toEqual('postgresql://user@localhost:5432/winrar')
    })

    test('allows database-less connection strings', () => {
      expect(
        new ConnectionString('postgresql://user@localhost:5432/db')
          .setDatabase(null)
          .toString()
      ).toEqual('postgresql://user@localhost:5432/')
    })
  })

  describe('database', () => {
    test('extracts db name', () => {
      expect(
        new ConnectionString('postgresql://user@localhost/db').database
      ).toEqual('db')
    })
  })

  describe('domain', () => {
    test('extracts domain', () => {
      expect(
        new ConnectionString('postgresql://user@localhost/db').domain
      ).toEqual('localhost')

      expect(
        new ConnectionString('postgresql://user@foo.com/db').domain
      ).toEqual('foo.com')

      expect(
        new ConnectionString('postgresql://user@foo.bar.com/db').domain
      ).toEqual('bar.com')
    })
  })

  describe('password', () => {
    test('extracts password', () => {
      expect(
        new ConnectionString('postgresql://user@localhost/db').password
      ).toEqual('')

      expect(
        new ConnectionString('postgresql://user:s3cr3t@localhost/db').password
      ).toEqual('s3cr3t')
    })
  })

  describe('username', () => {
    test('extracts username', () => {
      expect(
        new ConnectionString('postgresql://user:pass@localhost/db').username
      ).toEqual('user')

      expect(
        new ConnectionString('postgresql://user@localhost/db').username
      ).toEqual('user')
    })
  })

  test('get ssl mode', () => {
    expect(
      new ConnectionString(
        'postgresql://user:pass@localhost/db?sslmode=require'
      ).sslMode
    ).toEqual('require')

    expect(
      new ConnectionString('postgresql://user:pass@localhost/db').sslMode
    ).toEqual(null)
  })

  test('set ssl mode', () => {
    expect(
      new ConnectionString('postgresql://user:pass@localhost/db')
        .setSslMode('require')
        .toString()
    ).toEqual('postgresql://user:pass@localhost:5432/db?sslmode=require')

    expect(
      new ConnectionString(
        'postgresql://user:pass@localhost/db?sslmode=require'
      )
        .setSslMode(null)
        .toString()
    ).toEqual('postgresql://user:pass@localhost:5432/db')
  })

  describe('read only', () => {
    test('set read only', () => {
      expect(
        new ConnectionString('postgresql://user:pass@localhost/db')
          .setReadOnly(true)
          .toString()
      ).toMatchInlineSnapshot(
        `"postgresql://user:pass@localhost:5432/db?options=-c+default_transaction_read_only%3D1"`
      )

      expect(
        new ConnectionString(
          'postgresql://user:pass@localhost/db?options=-c+default_transaction_read_only%3D1'
        )
          .setReadOnly(true)
          .toString()
      ).toMatchInlineSnapshot(
        `"postgresql://user:pass@localhost:5432/db?options=-c+default_transaction_read_only%3D1"`
      )

      expect(
        new ConnectionString('postgresql://user:pass@localhost/db')
          .setReadOnly(true)
          .setReadOnly(false)
          .toString()
      ).toMatchInlineSnapshot(`"postgresql://user:pass@localhost:5432/db"`)

      expect(
        new ConnectionString('postgresql://user:pass@localhost/db').isReadOnly
      ).toEqual(false)

      expect(
        new ConnectionString('postgresql://user:pass@localhost/db').setReadOnly(
          true
        ).isReadOnly
      ).toEqual(true)
    })
  })
})
