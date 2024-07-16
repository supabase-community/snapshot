import { PredictedShape } from '~/db/structure.js'
import { piiImpact } from './piiImpact.js'
import { Shape } from '~/shapes.js'

describe(' Pii impact level', () => {
  test('predict pii impact based on shape and context', () => {
    const impact = piiImpact('PERSON', 'FULL_NAME')
    expect(impact).toEqual('HIGH')

    const impact2 = piiImpact('GENERAL', 'STATUS')
    expect(impact2).toEqual('LOW')
  })

  test('predict pii impact using typical implementation', () => {
    const predictedShape: PredictedShape[] = [
      {
        input: 'public users name character varying',
        column: 'name',
        shape: 'FIRST_NAME',
        confidence: 0.8,
        context: 'PERSON',
        confidenceContext: 0.5,
      },
      {
        input: 'public medical meta_data character varying',
        column: 'meta_data',
        shape: 'META_DATA',
        confidence: 0.9,
        context: 'HEALTH',
        confidenceContext: 0.6,
      },
    ]

    for (const entry of predictedShape) {
      const impact = piiImpact(entry.context!, entry.shape! as Shape)
      expect(impact).toEqual('HIGH')
    }
  })
})
