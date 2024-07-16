import type * as t from '@babel/types'

import { Shape } from '../shapes.js'
import { JsTypeName } from '../pgTypes.js'
import { ShapeExtra } from '~/shapeExtra.js'
import { ShapeGenerate } from '~/shapesGenerate.js'

export type TemplateField = {
  type: string
  name: string
  maxLength?: number
}

export interface TemplateContext {
  field: TemplateField
  shape: Shape | ShapeGenerate | null
  jsType: JsTypeName
  input: TemplateInputNode
}

export type TemplateInputNode = t.Expression | t.PatternLike | string

export type TemplateResult = string | null

export type TemplateFn = (api: TemplateContext) => TemplateResult

export type TypeTemplates = TemplateFn | TypeTemplatesRecord

export type TypeTemplatesRecord = Partial<
  Record<Shape | ShapeExtra | ShapeGenerate | '__DEFAULT', TemplateFn | null>
>

export type Templates<Type extends string = string> = Partial<
  Record<Type, TypeTemplates>
>
