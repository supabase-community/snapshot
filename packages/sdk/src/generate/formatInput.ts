import { snakeCase } from 'lodash'

export const formatInput = (values: string[]) => {
  return values.map((value) => `${snakeCase(value)}`).join(' ')
}
