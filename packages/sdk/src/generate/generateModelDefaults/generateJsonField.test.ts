import { generateJsonField } from './generateJsonField.js'

describe('generateJsonField', () => {
  test('it should generate a template from a json schema', () => {
    // arrange
    const jsonSchema = {
      $schema: 'http://json-schema.org/draft-06/schema#',
      $ref: '#/definitions/Storage',
      definitions: {
        Storage: {
          type: 'object',
          additionalProperties: false,
          properties: {
            data: {
              $ref: '#/definitions/Data',
            },
            version: {
              type: 'string',
              format: 'integer',
            },
          },
          required: ['data', 'version'],
          title: 'Storage',
        },
        Data: {
          type: 'object',
          additionalProperties: false,
          properties: {
            files: {
              $ref: '#/definitions/Files',
            },
            totalBytes: {
              type: 'integer',
            },
          },
          required: ['files', 'totalBytes'],
          title: 'Data',
        },
        File: {
          type: 'object',
          additionalProperties: false,
          properties: {
            md5: {
              type: 'string',
            },
            bytes: {
              type: 'integer',
            },
            filename: {
              type: 'string',
            },
            bucketKey: {
              type: 'string',
            },
          },
          required: ['bucketKey', 'bytes', 'filename', 'md5'],
          title: 'File',
        },
        Files: {
          type: 'array',
          items: {
            $ref: '#/definitions/File',
          },
          title: 'Files',
        },
      },
    }
    // act
    const template = generateJsonField({ schema: jsonSchema })
    // assert
    expect(template).toMatchInlineSnapshot(
      "\"{'data': {'files': [{'md5': copycat.word(seed + \\\"/data/files/0/md5\\\"), 'bytes': copycat.int(seed + \\\"/data/files/0/bytes\\\"), 'filename': copycat.word(seed + \\\"/data/files/0/filename\\\"), 'bucketKey': copycat.word(seed + \\\"/data/files/0/bucketKey\\\")}], 'totalBytes': copycat.int(seed + \\\"/data/totalBytes\\\")}, 'version': copycat.word(seed + \\\"/version\\\")}\""
    )
  })
})
