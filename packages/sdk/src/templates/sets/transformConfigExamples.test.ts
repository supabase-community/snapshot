import { mapValues } from 'lodash'

import { Shape } from '../../shapes.js'
import { evaluateGenerateColumn } from '../../generate/testing.js'
import { JsTypeName } from '~/pgTypes.js'
import { TRANSFORM_CONFIG_EXAMPLE_TEMPLATES } from './transformConfigExamples.js'

describe('TRANSFORM_CONFIG_EXAMPLE_TEMPLATES', () => {
  test('evaluation of generated code', () => {
    const results = mapValues(
      TRANSFORM_CONFIG_EXAMPLE_TEMPLATES,
      (templates, jsType) =>
        typeof templates !== 'function'
          ? mapValues(
              templates,
              (template, shape) =>
                template &&
                evaluateGenerateColumn(
                  template,
                  jsType as JsTypeName,
                  shape as Shape
                )
            )
          : evaluateGenerateColumn(
              templates,
              jsType as JsTypeName,
              '__DEFAULT' as Shape
            )
    )

    expect(results).toMatchInlineSnapshot(`
      {
        "bigint": {
          "INDEX": {
            "kind": "success",
            "value": 11641050,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 6447070,
          },
        },
        "bigserial": {
          "INDEX": {
            "kind": "success",
            "value": 11641050,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 6447070,
          },
        },
        "bit": {
          "kind": "success",
          "value": "01000000101011010110110111110000011001000011010101",
        },
        "bit varying": {
          "kind": "success",
          "value": "01000000101011010110110111110000011001000011010101",
        },
        "bool": {
          "kind": "success",
          "value": false,
        },
        "boolean": {
          "kind": "success",
          "value": false,
        },
        "box": {
          "kind": "success",
          "value": "(4, 6), (10, 9)",
        },
        "bpchar": {
          "AGE": {
            "kind": "success",
            "value": 15,
          },
          "CITY": {
            "kind": "success",
            "value": "Cicero",
          },
          "COUNTRY": {
            "kind": "success",
            "value": "Hong Kong",
          },
          "COUNTRY_CODE": {
            "kind": "success",
            "value": "SL",
          },
          "DATE": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "EMAIL": {
            "kind": "success",
            "value": "Oran_Kohler74811@thesejackfruit.info",
          },
          "ENVIRONMENT_VARIABLE": {
            "kind": "success",
            "value": "Graecis",
          },
          "FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "FULL_ADDRESS": {
            "kind": "success",
            "value": "551 Agustin Street, Everett 2985, Slovakia (Slovak Republic)",
          },
          "FULL_NAME": {
            "kind": "success",
            "value": "Myrtis Hartmann",
          },
          "INDEX": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "IP_ADDRESS": {
            "kind": "success",
            "value": "176.62.96.92",
          },
          "LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "MAC_ADDRESS": {
            "kind": "success",
            "value": "0f:ca:b9:63:d6:b7",
          },
          "NUMBER": {
            "kind": "success",
            "value": 931565393829854,
          },
          "PASSWORD": {
            "kind": "success",
            "value": "mS@yAdCM9&yvzt",
          },
          "PERSON_FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "PERSON_LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "PHONE": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "PHONE_NUMBER": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "POST_BODY": {
            "kind": "success",
            "value": "Ferre legamur eae nostrum es. Nec potes ant corpus ime timid inem, loqueruna ut facil continis uta. Legenim memin as quod fugit, oporum cum solamus cum pariantur de. De theseo sine ut per. Eturalios minus videret poetae identaneum debillime, multa a efficitat sed sicine si esse. Es sanos iderarbit odertim quam eorum licitur multi. Iucunt sapienter quis nec perferate ut vitamicat operosop, probari ea quae qua esse.",
          },
          "RATING": {
            "kind": "success",
            "value": 5,
          },
          "STATE": {
            "kind": "success",
            "value": "North Dakota",
          },
          "STREET_ADDRESS": {
            "kind": "success",
            "value": "805 Wuckert Trail",
          },
          "SYSTEM_SEMVER": {
            "kind": "success",
            "value": "4.4.4",
          },
          "TIMEZONE": {
            "kind": "success",
            "value": "Europe/Sofia",
          },
          "TOKEN": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "URL": {
            "kind": "success",
            "value": "https://whiff-dungeon.org",
          },
          "USERNAME": {
            "kind": "success",
            "value": "paralyse.flicker74811",
          },
          "USER_AGENT": {
            "kind": "success",
            "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_8 rv:4.0; HI) AppleWebKit/538.2.2 (KHTML, like Gecko) Version/5424.5903.1446 Safari/538.2.2",
          },
          "UUID": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "ZIP_CODE": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
        },
        "bytea": {
          "kind": "success",
          "value": "e",
        },
        "character": {
          "AGE": {
            "kind": "success",
            "value": 15,
          },
          "CITY": {
            "kind": "success",
            "value": "Cicero",
          },
          "COUNTRY": {
            "kind": "success",
            "value": "Hong Kong",
          },
          "COUNTRY_CODE": {
            "kind": "success",
            "value": "SL",
          },
          "DATE": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "EMAIL": {
            "kind": "success",
            "value": "Oran_Kohler74811@thesejackfruit.info",
          },
          "ENVIRONMENT_VARIABLE": {
            "kind": "success",
            "value": "Graecis",
          },
          "FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "FULL_ADDRESS": {
            "kind": "success",
            "value": "551 Agustin Street, Everett 2985, Slovakia (Slovak Republic)",
          },
          "FULL_NAME": {
            "kind": "success",
            "value": "Myrtis Hartmann",
          },
          "INDEX": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "IP_ADDRESS": {
            "kind": "success",
            "value": "176.62.96.92",
          },
          "LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "MAC_ADDRESS": {
            "kind": "success",
            "value": "0f:ca:b9:63:d6:b7",
          },
          "NUMBER": {
            "kind": "success",
            "value": 931565393829854,
          },
          "PASSWORD": {
            "kind": "success",
            "value": "mS@yAdCM9&yvzt",
          },
          "PERSON_FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "PERSON_LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "PHONE": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "PHONE_NUMBER": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "POST_BODY": {
            "kind": "success",
            "value": "Ferre legamur eae nostrum es. Nec potes ant corpus ime timid inem, loqueruna ut facil continis uta. Legenim memin as quod fugit, oporum cum solamus cum pariantur de. De theseo sine ut per. Eturalios minus videret poetae identaneum debillime, multa a efficitat sed sicine si esse. Es sanos iderarbit odertim quam eorum licitur multi. Iucunt sapienter quis nec perferate ut vitamicat operosop, probari ea quae qua esse.",
          },
          "RATING": {
            "kind": "success",
            "value": 5,
          },
          "STATE": {
            "kind": "success",
            "value": "North Dakota",
          },
          "STREET_ADDRESS": {
            "kind": "success",
            "value": "805 Wuckert Trail",
          },
          "SYSTEM_SEMVER": {
            "kind": "success",
            "value": "4.4.4",
          },
          "TIMEZONE": {
            "kind": "success",
            "value": "Europe/Sofia",
          },
          "TOKEN": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "URL": {
            "kind": "success",
            "value": "https://whiff-dungeon.org",
          },
          "USERNAME": {
            "kind": "success",
            "value": "paralyse.flicker74811",
          },
          "USER_AGENT": {
            "kind": "success",
            "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_8 rv:4.0; HI) AppleWebKit/538.2.2 (KHTML, like Gecko) Version/5424.5903.1446 Safari/538.2.2",
          },
          "UUID": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "ZIP_CODE": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
        },
        "character varying": {
          "AGE": {
            "kind": "success",
            "value": 15,
          },
          "CITY": {
            "kind": "success",
            "value": "Cicero",
          },
          "COUNTRY": {
            "kind": "success",
            "value": "Hong Kong",
          },
          "COUNTRY_CODE": {
            "kind": "success",
            "value": "SL",
          },
          "DATE": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "EMAIL": {
            "kind": "success",
            "value": "Oran_Kohler74811@thesejackfruit.info",
          },
          "ENVIRONMENT_VARIABLE": {
            "kind": "success",
            "value": "Graecis",
          },
          "FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "FULL_ADDRESS": {
            "kind": "success",
            "value": "551 Agustin Street, Everett 2985, Slovakia (Slovak Republic)",
          },
          "FULL_NAME": {
            "kind": "success",
            "value": "Myrtis Hartmann",
          },
          "INDEX": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "IP_ADDRESS": {
            "kind": "success",
            "value": "176.62.96.92",
          },
          "LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "MAC_ADDRESS": {
            "kind": "success",
            "value": "0f:ca:b9:63:d6:b7",
          },
          "NUMBER": {
            "kind": "success",
            "value": 931565393829854,
          },
          "PASSWORD": {
            "kind": "success",
            "value": "mS@yAdCM9&yvzt",
          },
          "PERSON_FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "PERSON_LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "PHONE": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "PHONE_NUMBER": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "POST_BODY": {
            "kind": "success",
            "value": "Ferre legamur eae nostrum es. Nec potes ant corpus ime timid inem, loqueruna ut facil continis uta. Legenim memin as quod fugit, oporum cum solamus cum pariantur de. De theseo sine ut per. Eturalios minus videret poetae identaneum debillime, multa a efficitat sed sicine si esse. Es sanos iderarbit odertim quam eorum licitur multi. Iucunt sapienter quis nec perferate ut vitamicat operosop, probari ea quae qua esse.",
          },
          "RATING": {
            "kind": "success",
            "value": 5,
          },
          "STATE": {
            "kind": "success",
            "value": "North Dakota",
          },
          "STREET_ADDRESS": {
            "kind": "success",
            "value": "805 Wuckert Trail",
          },
          "SYSTEM_SEMVER": {
            "kind": "success",
            "value": "4.4.4",
          },
          "TIMEZONE": {
            "kind": "success",
            "value": "Europe/Sofia",
          },
          "TOKEN": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "URL": {
            "kind": "success",
            "value": "https://whiff-dungeon.org",
          },
          "USERNAME": {
            "kind": "success",
            "value": "paralyse.flicker74811",
          },
          "USER_AGENT": {
            "kind": "success",
            "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_8 rv:4.0; HI) AppleWebKit/538.2.2 (KHTML, like Gecko) Version/5424.5903.1446 Safari/538.2.2",
          },
          "UUID": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "ZIP_CODE": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
        },
        "cidr": {
          "kind": "success",
          "value": "176.62.96.92",
        },
        "circle": {
          "kind": "success",
          "value": "((4, 6 ), 10 )",
        },
        "citext": {
          "AGE": {
            "kind": "success",
            "value": 15,
          },
          "CITY": {
            "kind": "success",
            "value": "Cicero",
          },
          "COUNTRY": {
            "kind": "success",
            "value": "Hong Kong",
          },
          "COUNTRY_CODE": {
            "kind": "success",
            "value": "SL",
          },
          "DATE": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "EMAIL": {
            "kind": "success",
            "value": "Oran_Kohler74811@thesejackfruit.info",
          },
          "ENVIRONMENT_VARIABLE": {
            "kind": "success",
            "value": "Graecis",
          },
          "FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "FULL_ADDRESS": {
            "kind": "success",
            "value": "551 Agustin Street, Everett 2985, Slovakia (Slovak Republic)",
          },
          "FULL_NAME": {
            "kind": "success",
            "value": "Myrtis Hartmann",
          },
          "INDEX": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "IP_ADDRESS": {
            "kind": "success",
            "value": "176.62.96.92",
          },
          "LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "MAC_ADDRESS": {
            "kind": "success",
            "value": "0f:ca:b9:63:d6:b7",
          },
          "NUMBER": {
            "kind": "success",
            "value": 931565393829854,
          },
          "PASSWORD": {
            "kind": "success",
            "value": "mS@yAdCM9&yvzt",
          },
          "PERSON_FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "PERSON_LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "PHONE": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "PHONE_NUMBER": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "POST_BODY": {
            "kind": "success",
            "value": "Ferre legamur eae nostrum es. Nec potes ant corpus ime timid inem, loqueruna ut facil continis uta. Legenim memin as quod fugit, oporum cum solamus cum pariantur de. De theseo sine ut per. Eturalios minus videret poetae identaneum debillime, multa a efficitat sed sicine si esse. Es sanos iderarbit odertim quam eorum licitur multi. Iucunt sapienter quis nec perferate ut vitamicat operosop, probari ea quae qua esse.",
          },
          "RATING": {
            "kind": "success",
            "value": 5,
          },
          "STATE": {
            "kind": "success",
            "value": "North Dakota",
          },
          "STREET_ADDRESS": {
            "kind": "success",
            "value": "805 Wuckert Trail",
          },
          "SYSTEM_SEMVER": {
            "kind": "success",
            "value": "4.4.4",
          },
          "TIMEZONE": {
            "kind": "success",
            "value": "Europe/Sofia",
          },
          "TOKEN": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "URL": {
            "kind": "success",
            "value": "https://whiff-dungeon.org",
          },
          "USERNAME": {
            "kind": "success",
            "value": "paralyse.flicker74811",
          },
          "USER_AGENT": {
            "kind": "success",
            "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_8 rv:4.0; HI) AppleWebKit/538.2.2 (KHTML, like Gecko) Version/5424.5903.1446 Safari/538.2.2",
          },
          "UUID": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "ZIP_CODE": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
        },
        "date": {
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "2020-03-15",
          },
        },
        "decimal": {
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 1.6547925586782493,
          },
        },
        "double precision": {
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 26.476680938851988,
          },
        },
        "float4": {
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 1.6547925586782493,
          },
        },
        "float8": {
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 26.476680938851988,
          },
        },
        "inet": {
          "kind": "success",
          "value": "176.62.96.92",
        },
        "int": {
          "INDEX": {
            "kind": "success",
            "value": 42885,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 24542,
          },
        },
        "int16": {
          "INDEX": {
            "kind": "success",
            "value": 11641050,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 6447070,
          },
        },
        "int2": {
          "INDEX": {
            "kind": "success",
            "value": 45,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 222,
          },
        },
        "int32": {
          "INDEX": {
            "kind": "success",
            "value": 11641050,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 6447070,
          },
        },
        "int4": {
          "INDEX": {
            "kind": "success",
            "value": 42885,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 24542,
          },
        },
        "int8": {
          "INDEX": {
            "kind": "success",
            "value": 11641050,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 6447070,
          },
        },
        "integer": {
          "INDEX": {
            "kind": "success",
            "value": 42885,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 24542,
          },
        },
        "interval": {
          "kind": "success",
          "value": 3,
        },
        "json": {
          "STATUS": {
            "kind": "success",
            "value": {
              "status": "success",
            },
          },
          "__DEFAULT": {
            "kind": "success",
            "value": {
              "Graecis": "Vim in",
            },
          },
        },
        "jsonb": {
          "STATUS": {
            "kind": "success",
            "value": {
              "status": "success",
            },
          },
          "__DEFAULT": {
            "kind": "success",
            "value": {
              "Graecis": "Vim in",
            },
          },
        },
        "line": {
          "kind": "success",
          "value": "(4, 6), (10, 9)",
        },
        "lseg": {
          "kind": "success",
          "value": "(4, 6), (10, 9)",
        },
        "macaddr": {
          "kind": "success",
          "value": "0f:ca:b9:63:d6:b7",
        },
        "macaddr8": {
          "kind": "success",
          "value": "0f:ca:b9:63:d6:b7",
        },
        "money": {
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 26.476680938851988,
          },
        },
        "numeric": {
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 1.6547925586782493,
          },
        },
        "path": {
          "kind": "success",
          "value": "(4, 6), (10, 9)",
        },
        "pg_lsn": {
          "kind": "success",
          "value": NaN,
        },
        "point": {
          "kind": "success",
          "value": "(3,3)",
        },
        "real": {
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 1.6547925586782493,
          },
        },
        "serial": {
          "INDEX": {
            "kind": "success",
            "value": 42885,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 24542,
          },
        },
        "serial2": {
          "INDEX": {
            "kind": "success",
            "value": 45,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 222,
          },
        },
        "serial4": {
          "INDEX": {
            "kind": "success",
            "value": 42885,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 24542,
          },
        },
        "serial8": {
          "INDEX": {
            "kind": "success",
            "value": 11641050,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 6447070,
          },
        },
        "smallint": {
          "INDEX": {
            "kind": "success",
            "value": 45,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 222,
          },
        },
        "smallserial": {
          "INDEX": {
            "kind": "success",
            "value": 45,
          },
          "LATITUDE": {
            "kind": "success",
            "value": 28,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": 28,
          },
          "__DEFAULT": {
            "kind": "success",
            "value": 222,
          },
        },
        "text": {
          "AGE": {
            "kind": "success",
            "value": 15,
          },
          "CITY": {
            "kind": "success",
            "value": "Cicero",
          },
          "COUNTRY": {
            "kind": "success",
            "value": "Hong Kong",
          },
          "COUNTRY_CODE": {
            "kind": "success",
            "value": "SL",
          },
          "DATE": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "EMAIL": {
            "kind": "success",
            "value": "Oran_Kohler74811@thesejackfruit.info",
          },
          "ENVIRONMENT_VARIABLE": {
            "kind": "success",
            "value": "Graecis",
          },
          "FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "FULL_ADDRESS": {
            "kind": "success",
            "value": "551 Agustin Street, Everett 2985, Slovakia (Slovak Republic)",
          },
          "FULL_NAME": {
            "kind": "success",
            "value": "Myrtis Hartmann",
          },
          "INDEX": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "IP_ADDRESS": {
            "kind": "success",
            "value": "176.62.96.92",
          },
          "LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "MAC_ADDRESS": {
            "kind": "success",
            "value": "0f:ca:b9:63:d6:b7",
          },
          "NUMBER": {
            "kind": "success",
            "value": 931565393829854,
          },
          "PASSWORD": {
            "kind": "success",
            "value": "mS@yAdCM9&yvzt",
          },
          "PERSON_FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "PERSON_LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "PHONE": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "PHONE_NUMBER": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "POST_BODY": {
            "kind": "success",
            "value": "Ferre legamur eae nostrum es. Nec potes ant corpus ime timid inem, loqueruna ut facil continis uta. Legenim memin as quod fugit, oporum cum solamus cum pariantur de. De theseo sine ut per. Eturalios minus videret poetae identaneum debillime, multa a efficitat sed sicine si esse. Es sanos iderarbit odertim quam eorum licitur multi. Iucunt sapienter quis nec perferate ut vitamicat operosop, probari ea quae qua esse.",
          },
          "RATING": {
            "kind": "success",
            "value": 5,
          },
          "STATE": {
            "kind": "success",
            "value": "North Dakota",
          },
          "STREET_ADDRESS": {
            "kind": "success",
            "value": "805 Wuckert Trail",
          },
          "SYSTEM_SEMVER": {
            "kind": "success",
            "value": "4.4.4",
          },
          "TIMEZONE": {
            "kind": "success",
            "value": "Europe/Sofia",
          },
          "TOKEN": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "URL": {
            "kind": "success",
            "value": "https://whiff-dungeon.org",
          },
          "USERNAME": {
            "kind": "success",
            "value": "paralyse.flicker74811",
          },
          "USER_AGENT": {
            "kind": "success",
            "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_8 rv:4.0; HI) AppleWebKit/538.2.2 (KHTML, like Gecko) Version/5424.5903.1446 Safari/538.2.2",
          },
          "UUID": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "ZIP_CODE": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
        },
        "time": {
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "14:27:04",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "14:27:04",
          },
        },
        "timestamp": {
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
        },
        "timestamptz": {
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
        },
        "tsquery": {
          "kind": "success",
          "value": "Graecis",
        },
        "tsvector": {
          "kind": "success",
          "value": "Graecis",
        },
        "uuid": {
          "kind": "success",
          "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
        },
        "varbit": {
          "kind": "success",
          "value": "01000000101011010110110111110000011001000011010101",
        },
        "varchar": {
          "AGE": {
            "kind": "success",
            "value": 15,
          },
          "CITY": {
            "kind": "success",
            "value": "Cicero",
          },
          "COUNTRY": {
            "kind": "success",
            "value": "Hong Kong",
          },
          "COUNTRY_CODE": {
            "kind": "success",
            "value": "SL",
          },
          "DATE": {
            "kind": "success",
            "value": "2020-03-15T14:27:04.000Z",
          },
          "DATE_OF_BIRTH": {
            "kind": "success",
            "value": "1994-03-15T14:27:04.000Z",
          },
          "EMAIL": {
            "kind": "success",
            "value": "Oran_Kohler74811@thesejackfruit.info",
          },
          "ENVIRONMENT_VARIABLE": {
            "kind": "success",
            "value": "Graecis",
          },
          "FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "FULL_ADDRESS": {
            "kind": "success",
            "value": "551 Agustin Street, Everett 2985, Slovakia (Slovak Republic)",
          },
          "FULL_NAME": {
            "kind": "success",
            "value": "Myrtis Hartmann",
          },
          "INDEX": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "IP_ADDRESS": {
            "kind": "success",
            "value": "176.62.96.92",
          },
          "LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "LATITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "LONGITUDE": {
            "kind": "success",
            "value": -71.3835837148697,
          },
          "MAC_ADDRESS": {
            "kind": "success",
            "value": "0f:ca:b9:63:d6:b7",
          },
          "NUMBER": {
            "kind": "success",
            "value": 931565393829854,
          },
          "PASSWORD": {
            "kind": "success",
            "value": "mS@yAdCM9&yvzt",
          },
          "PERSON_FIRST_NAME": {
            "kind": "success",
            "value": "Mireille",
          },
          "PERSON_LAST_NAME": {
            "kind": "success",
            "value": "Daugherty",
          },
          "PHONE": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "PHONE_NUMBER": {
            "kind": "success",
            "value": "+931565393829854",
          },
          "POST_BODY": {
            "kind": "success",
            "value": "Ferre legamur eae nostrum es. Nec potes ant corpus ime timid inem, loqueruna ut facil continis uta. Legenim memin as quod fugit, oporum cum solamus cum pariantur de. De theseo sine ut per. Eturalios minus videret poetae identaneum debillime, multa a efficitat sed sicine si esse. Es sanos iderarbit odertim quam eorum licitur multi. Iucunt sapienter quis nec perferate ut vitamicat operosop, probari ea quae qua esse.",
          },
          "RATING": {
            "kind": "success",
            "value": 5,
          },
          "STATE": {
            "kind": "success",
            "value": "North Dakota",
          },
          "STREET_ADDRESS": {
            "kind": "success",
            "value": "805 Wuckert Trail",
          },
          "SYSTEM_SEMVER": {
            "kind": "success",
            "value": "4.4.4",
          },
          "TIMEZONE": {
            "kind": "success",
            "value": "Europe/Sofia",
          },
          "TOKEN": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "URL": {
            "kind": "success",
            "value": "https://whiff-dungeon.org",
          },
          "USERNAME": {
            "kind": "success",
            "value": "paralyse.flicker74811",
          },
          "USER_AGENT": {
            "kind": "success",
            "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_8 rv:4.0; HI) AppleWebKit/538.2.2 (KHTML, like Gecko) Version/5424.5903.1446 Safari/538.2.2",
          },
          "UUID": {
            "kind": "success",
            "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
          },
          "ZIP_CODE": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
          "__DEFAULT": {
            "kind": "success",
            "value": "dovoggMisvr",
          },
        },
        "xml": {
          "kind": "success",
          "value": "<Graecis>Vim in</Graecis>",
        },
      }
    `)
  })
})
