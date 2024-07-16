export function generateSelectTypes() {
  return `//#region select
type SelectedTable = { id: string; schema: string; table: string };

type SelectDefault = {
  /**
   * Define the "default" behavior to use for the tables in the schema.
   * If true, select all tables in the schema.
   * If false, select no tables in the schema.
   * If "structure", select only the structure of the tables in the schema but not the data.
   * @defaultValue true
   */
  $default?: SelectObject;
};

type DefaultKey = keyof SelectDefault;

type SelectObject = boolean | "structure";

type ExtensionsSelect<TSchema extends keyof Database> =
  TSchema extends keyof Extension
    ? {
        /**
         * Define if you want to select the extension data.
         * @defaultValue false
         */
        $extensions?:
          | boolean
          | {
              [TExtension in Extension[TSchema]]?: boolean;
            };
      }
    : {};

type SelectConfig = SelectDefault & {
  [TSchema in keyof Database]?:
    | SelectObject
    | (SelectDefault &
        ExtensionsSelect<TSchema> & {
          [TTable in keyof Database[TSchema]]?: SelectObject;
        });
};

// Apply the __default key if it exists to each level of the select config (schemas and tables)
type ApplyDefault<TSelectConfig extends SelectConfig> = {
  [TSchema in keyof Database]-?: {
    [TTable in keyof Database[TSchema]]-?: TSelectConfig[TSchema] extends SelectObject
      ? TSelectConfig[TSchema]
      : TSelectConfig[TSchema] extends Record<any, any>
      ? TSelectConfig[TSchema][TTable] extends SelectObject
        ? TSelectConfig[TSchema][TTable]
        : TSelectConfig[TSchema][DefaultKey] extends SelectObject
        ? TSelectConfig[TSchema][DefaultKey]
        : TSelectConfig[DefaultKey] extends SelectObject
        ? TSelectConfig[DefaultKey]
        : true
      : TSelectConfig[DefaultKey] extends SelectObject
      ? TSelectConfig[DefaultKey]
      : true;
  };
};

type ExtractValues<T> = T extends object ? T[keyof T] : never;

type GetSelectedTable<TSelectSchemas extends SelectConfig> = ExtractValues<
  ExtractValues<{
    [TSchema in keyof TSelectSchemas]: {
      [TTable in keyof TSelectSchemas[TSchema] as TSelectSchemas[TSchema][TTable] extends true
        ? TTable
        : never]: TSchema extends string
        ? TTable extends string
          ? { id: \`\${TSchema}.\${TTable}\`; schema: TSchema; table: TTable }
          : never
        : never;
    };
  }>
>;
//#endregion`
}
