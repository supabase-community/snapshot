import { copycat } from '@snaplet/copycat'
import { getTransform } from '../../generate/generateTransform.js'
import { findShape, Shape } from '../../shapes.js'
import { loadModule } from '../../config/loadModule.js'
import {
  extractPrimitivePgType,
  isNestedArrayPgType,
  PgTypeName,
  PG_TO_JS_TYPES,
} from '../../pgTypes.js'
import { PredictedShape } from '~/db/structure.js'
import { SHAPE_PREDICTION_CONFIDENCE_THRESHOLD } from '~/pii.js'

import { xdebug } from '~/x/xdebug.js'
import { ShapeGenerate } from '~/shapesGenerate.js'

export const xdebugSeed = xdebug.extend('seed')

const createGenerateCode = (
  transformCode: string
) => `module.exports = function(seedValue) {
  var ccModule = require('@snaplet/copycat');
  const copycat = ccModule.copycat;
  const faker = ccModule.faker;
  return ${transformCode}
}`

export const generateDataUsingShape = async (
  col: { type: string; name: string },
  seedValue: string,
  predictedShape: PredictedShape | null
) => {
  const { generateColumnTransformCode } = await getTransform()

  const jsType = PG_TO_JS_TYPES[col.type as PgTypeName]

  if (!jsType) {
    return null
  }
  let shape: Shape | ShapeGenerate | undefined
  if (
    predictedShape &&
    predictedShape.shape &&
    predictedShape.confidence &&
    predictedShape.confidence > SHAPE_PREDICTION_CONFIDENCE_THRESHOLD
  ) {
    shape = predictedShape?.shape
  } else {
    shape = findShape(col.name, jsType)?.shape
  }
  if (!shape) {
    return null
  }
  const transformCode = generateColumnTransformCode('seedValue', col, shape)
  if (transformCode) {
    const code = createGenerateCode(transformCode)
    const seedFunction = loadModule<any>('vm.js', {
      source: code,
      cache: await getCodeDeps(),
      shouldCompile: false,
      require: (name) =>
        name === '@snaplet/copycat/next'
          ? require('@snaplet/copycat/next')
          : null,
    })
    return seedFunction(seedValue)
  }

  return null
}

export const generateDataFallback = (
  col: {
    type: string
    maxLength?: number
    nullable: boolean
  },
  seedValue: string
) => {
  const isArray = isNestedArrayPgType(col.type)
  const type = extractPrimitivePgType(col.type) as string

  switch (type) {
    case 'bit': // We need length todo this corectly
    case 'varbit':
    case 'bit varying': {
      const len = col.maxLength || 1
      let bits = ''
      for (let i = 0; i < len; i++) {
        bits += copycat.oneOf(seedValue + i, ['0', '1'])
      }
      return isArray ? [] : bits
    }
    case 'bytea':
    case 'uuid': {
      const uuid = copycat.uuid(seedValue)
      return isArray ? [uuid] : uuid
    }
    case 'point': {
      const point = `(${copycat.int(seedValue, { max: 10 })},${copycat.int(
        seedValue,
        { max: 10 }
      )})`
      return isArray ? [point] : point
    }
    case 'lseg':
    case 'path':
    case 'box':
    case 'line': {
      const points = uniquePoints(seedValue, 4)
      const line = `( ${points[0]} , ${points[1]} ), ( ${points[2]} , ${points[3]} )`
      return isArray ? [line] : line
    }
    case 'circle': {
      const points = uniquePoints(seedValue, 3)
      const circle = `( ( ${points[0]} , ${points[1]} ) , ${points[2]} )`
      return isArray ? [circle] : circle
    }
    case 'macaddr8':
    case 'macaddr': {
      const macaddr = copycat.mac(seedValue)
      return isArray ? [macaddr] : macaddr
    }
    case 'bpchar':
    case 'character': // We need length todo this corectly
    case 'character varying':
    case 'varchar': {
      const varchar = copycat
        .words(seedValue, {
          minSyllables: 5,
          maxSyllables: 10,
        })
        .slice(0, col.maxLength || 50)

      return isArray ? [varchar] : varchar
    }
    case 'inet':
    case 'cidr': {
      const ip = copycat.ipv4(seedValue)
      return isArray ? [ip] : ip
    }
    case 'citext':
    case 'text': {
      const text = copycat.words(seedValue)
      return isArray ? [text] : text
    }
    case 'boolean':
    case 'bool': {
      const bool = copycat.bool(seedValue)
      return isArray ? [bool] : bool
    }
    case 'date': {
      const date = copycat.dateString(seedValue).slice(0, 10)
      return isArray ? [date] : date
    }
    case 'time': {
      const time = copycat.dateString(seedValue).slice(11, 19)
      return isArray ? [time] : time
    }
    case 'timestamptz':
    case 'timestamp': {
      const date = copycat.dateString(seedValue)
      return isArray ? [date] : date
    }
    case 'interval': {
      const interval = `${copycat.int(seedValue, { max: 10 })}`
      return isArray ? [interval] : interval
    }
    case 'smallint':
    case 'smallserial':
    case 'serial2':
    case 'int2': {
      // For int2, the maximum value is 2^(8*2 - 1) - 1
      const intVar = copycat.int(seedValue, { max: Math.pow(2, 15) - 1 })
      return isArray ? [intVar] : intVar
    }
    case 'serial':
    case 'serial4':
    case 'integer':
    case 'int':
    case 'int4':
    case 'oid': {
      // For int4, the maximum value is 2^(8*4 - 1) - 1
      const intVar = copycat.int(seedValue, { max: Math.pow(2, 31) - 1 })
      return isArray ? [intVar] : intVar
    }
    case 'bigint':
    case 'bigserial':
    case 'serial8':
    case 'int8':
    case 'int16':
    case 'int32': {
      // For int8, the maximum value is 2^(8*8 - 1) - 1, but we use the max safe integer in JavaScript
      const intVar = copycat.int(seedValue, { max: Number.MAX_SAFE_INTEGER })
      return isArray ? [intVar] : intVar
    }
    case 'jsonb':
    case 'json':
      return isArray
        ? []
        : { [copycat.word(seedValue)]: copycat.words(seedValue) }
    case 'real':
    case 'float4': {
      // PostgreSQL 'real' is a 4-byte floating point. We will limit to JavaScript's single precision range.
      const float = copycat.float(seedValue, {
        min: -Math.pow(2, 24),
        max: Math.pow(2, 24),
      })
      return isArray ? [float] : float
    }
    case 'double precision':
    case 'float8': {
      // PostgreSQL 'double precision' is an 8-byte floating point. We will use JavaScript's double precision range.
      const float = copycat.float(seedValue, {
        min: -Number.MAX_VALUE,
        max: Number.MAX_VALUE,
      })
      return isArray ? [float] : float
    }
    case 'numeric':
    case 'decimal': {
      // PostgreSQL 'numeric' and 'decimal' types have a wide range and precision can be set by the user.
      // We will use an arbitrary precision for seeding purposes.
      // If specific precision and scale are needed, they should be overriden by the user.
      const decimal = copycat.float(seedValue, {
        min: -1000000,
        max: 1000000,
      })
      return isArray ? [decimal] : decimal
    }
    case 'money': {
      const float = copycat.float(seedValue, { max: Math.pow(2, 8) })
      return isArray ? [float] : float
    }
    case 'tsquery': {
      const tsquery = copycat.word(seedValue)
      return isArray ? [tsquery] : tsquery
    }
    case 'tsvector': {
      const tsvector = `${copycat.word(seedValue)}:1`
      return isArray ? [tsvector] : tsvector
    }
    case 'pg_lsn': {
      const lsn = `${copycat.hex(seedValue)}/${copycat.hex(seedValue)}`
      return isArray ? [lsn] : lsn
    }
    case 'xml': {
      const xml = `<${copycat.word(seedValue)}>${copycat.words(
        seedValue
      )}</${copycat.word(seedValue)}>`
      return isArray ? [xml] : xml
    }
    case 'regproc':
      return 'sum'
    case 'regprocedure':
      return 'sum(integer)'
    case 'regoper':
      return '+'
    case 'regoperator':
      return '+(integer,integer)'
    case 'regtype':
      return 'integer'
    case 'regclass':
      return 'pg_type'
    case 'regconfig':
      return 'english'
    case 'regdictionary':
      return 'simple'
    // Unsupported types
    // case 'pg_snapshot':
    // case 'txid_snapshot':
    default: {
      console.log(`Unknown column type: ${col.type}.`)
      if (col.nullable) {
        console.log('Column is nullable - Returning null')
        return null
      } else {
        console.log('Column is not nullable - Returning empty string')
        console.log(`
        Note: We rather attempt to insert an empty string when we dont know the type.
        If the seed is still unsuccesful. You can add a custom value to the column in the seed.ts config file.
        Otherwise skip this table by setting it false in snaplet.config.ts file.`)
        return ' '
      }
    }
  }
}

const getCodeDeps = async (): Promise<{
  '@snaplet/copycat': Awaited<typeof import('@snaplet/copycat')>
  snaplet: { defineConfig: <Config>(config: Config) => Config }
}> => ({
  '@snaplet/copycat': await import('@snaplet/copycat'),
  snaplet: { defineConfig: (config: any) => config },
})

const uniquePoints = (seedValue: string, amount: number) => {
  let options = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  const points = []
  for (let i = 0; i < amount; i++) {
    const value = copycat.oneOf(seedValue, options)
    points.push(value)
    options = options.filter((p) => p !== value)
  }
  return points
}
