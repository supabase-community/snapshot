import { generateSubsetTypes } from './generateSubsetTypes.js'
import { generateSelectTypes } from './generateSelectTypes.js'
import { generateStructureTypes } from './generateStructureTypes.js'
import { generateTransformTypes } from './generateTransformTypes.js'
import { generateIntrospectTypes } from './generateIntrospectTypes.js'
import { IntrospectedStructure } from '../../../../db/introspect/introspectDatabase.js'

export function generateTypedefInclusion() {
  return `// eslint-disable-next-line @typescript-eslint/triple-slash-reference
/// <reference path=".snaplet/snaplet.d.ts" />`
}

export function generateTypes(structure: IntrospectedStructure) {
  return `${generateStructureTypes(structure)}

${generateSelectTypes()}

${generateTransformTypes()}

${generateSubsetTypes()}

${generateIntrospectTypes()}

${generateTypedConfig()}

${generateDefineConfig()}`
}

function generateTypedConfig() {
  return `type Validate<T, Target> = {
  [K in keyof T]: K extends keyof Target ? T[K] : never;
};

type TypedConfig<
  TSelectConfig extends SelectConfig,
  TTransformMode extends TransformMode
> =  GetSelectedTable<
  ApplyDefault<TSelectConfig>
> extends SelectedTable
  ? {
    /**
     * Parameter to configure the generation of data.
     * {@link https://docs.snaplet.dev/core-concepts/seed}
     */
      seed?: {
        alias?: import("./snaplet-client").Alias;
        fingerprint?: import("./snaplet-client").Fingerprint;
      }
    /**
     * Parameter to configure the inclusion/exclusion of schemas and tables from the snapshot.
     * {@link https://docs.snaplet.dev/reference/configuration#select}
     */
      select?: Validate<TSelectConfig, SelectConfig>;
      /**
       * Parameter to configure the transformations applied to the data.
       * {@link https://docs.snaplet.dev/reference/configuration#transform}
       */
      transform?: TransformConfig<TTransformMode, GetSelectedTable<ApplyDefault<TSelectConfig>>>;
      /**
       * Parameter to capture a subset of the data.
       * {@link https://docs.snaplet.dev/reference/configuration#subset}
       */
      subset?: SubsetConfig<GetSelectedTable<ApplyDefault<TSelectConfig>>>;

      /**
       * Parameter to augment the result of the introspection of your database.
       * {@link https://docs.snaplet.dev/references/data-operations/introspect}
       */
      introspect?: IntrospectConfig<GetSelectedTable<ApplyDefault<TSelectConfig>>>;
    }
  : never;`
}

function generateDefineConfig() {
  return `declare module "snaplet" {
  class JsonNull {}
  type JsonClass = typeof JsonNull;
  /**
   * Use this value to explicitely set a json or jsonb column to json null instead of the database NULL value.
   */
  export const jsonNull: InstanceType<JsonClass>;
  /**
  * Define the configuration for Snaplet capture process.
  * {@link https://docs.snaplet.dev/reference/configuration}
  */
  export function defineConfig<
    TSelectConfig extends SelectConfig,
    TTransformMode extends TransformMode = undefined
  >(
    config: TypedConfig<TSelectConfig, TTransformMode>
  ): TypedConfig<TSelectConfig, TTransformMode>;
}`
}
