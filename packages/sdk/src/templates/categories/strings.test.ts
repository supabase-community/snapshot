import { mapValues } from 'lodash'

import { strings } from './strings.js'
import { Shape } from '~/shapes.js'
import { evaluateGenerateColumn } from '../testing.js'

describe('strings', () => {
  test('evaluation of generated code', () => {
    const results = mapValues(
      strings,
      (template, shape) =>
        template && evaluateGenerateColumn(template, 'string', shape as Shape)
    )

    expect(results).toMatchInlineSnapshot(`
      {
        "AGE": {
          "kind": "success",
          "value": "15",
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
          "value": "551 Agustin Street, Everett 2985, Slovakia (Slovak",
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
          "value": "-71.3835837148697",
        },
        "LONGITUDE": {
          "kind": "success",
          "value": "-71.3835837148697",
        },
        "MAC_ADDRESS": {
          "kind": "success",
          "value": "0f:ca:b9:63:d6:b7",
        },
        "NUMBER": {
          "kind": "success",
          "value": "931565393829854",
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
          "value": "Ferre legamur eae nostrum es. Nec potes ant corpus",
        },
        "RATING": {
          "kind": "success",
          "value": "5",
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
          "value": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_8 rv:",
        },
        "UUID": {
          "kind": "success",
          "value": "2afcff4e-718d-5a9b-a808-587c85fd225c",
        },
        "__DEFAULT": {
          "kind": "success",
          "value": "Temperciplin es expetiuntur ipsis ad ent numererit",
        },
      }
    `)
  })
})
