import { TypeTemplates } from '../types.js'
import { copycatTemplate } from '../copycat.js'

export const strings: TypeTemplates = {
  EMAIL: copycatTemplate('email'),
  USERNAME: copycatTemplate('username'),
  FIRST_NAME: copycatTemplate('firstName'),
  LAST_NAME: copycatTemplate('lastName'),
  PERSON_FIRST_NAME: copycatTemplate('firstName'),
  PERSON_LAST_NAME: copycatTemplate('lastName'),
  FULL_NAME: copycatTemplate('fullName'),
  URL: copycatTemplate('url'),
  UUID: copycatTemplate('uuid'),
  INDEX: ({ input }) => `copycat.uuid(${input})`,
  TOKEN: ({ input }) => `copycat.uuid(${input})`,
  AGE: copycatTemplate('int', { options: { min: 1, max: 80 } }),
  NUMBER: copycatTemplate('int'),
  DATE_OF_BIRTH: copycatTemplate('dateString', { options: { maxYear: 1999 } }),
  DATE: copycatTemplate('dateString', { options: { minYear: 2020 } }),
  PASSWORD: copycatTemplate('password'),
  // We are still using the old model for snapshots (and old cli versions) so need both templates
  PHONE: copycatTemplate('phoneNumber'),
  PHONE_NUMBER: copycatTemplate('phoneNumber'),
  USER_AGENT: copycatTemplate('userAgent'),

  CITY: copycatTemplate('city'),
  COUNTRY: copycatTemplate('country'),
  COUNTRY_CODE: copycatTemplate('countryCode'),

  FULL_ADDRESS: copycatTemplate('postalAddress'),
  STREET_ADDRESS: copycatTemplate('streetAddress'),
  LATITUDE: copycatTemplate('float', { options: { min: -90, max: 90 } }),
  LONGITUDE: copycatTemplate('float', { options: { min: -90, max: 90 } }),
  STATE: copycatTemplate('state'),
  TIMEZONE: copycatTemplate('timezone'),

  IP_ADDRESS: copycatTemplate('ipv4'),
  MAC_ADDRESS: copycatTemplate('mac'),
  SYSTEM_SEMVER: ({ input }) =>
    `copycat.digit( ${input} ) + '.' + copycat.digit( ${input} ) + '.' + copycat.digit( ${input} )`,
  POST_BODY: copycatTemplate('paragraph'),
  RATING: copycatTemplate('int', { options: { min: 1, max: 5 } }),
  ENVIRONMENT_VARIABLE: copycatTemplate('word'),
  __DEFAULT: copycatTemplate(`sentence`),
}
