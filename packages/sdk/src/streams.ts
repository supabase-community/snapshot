export const createEffectStream = <Data>(
  effectFn: (data: Data) => unknown | Promise<unknown>
) => {
  const gen = async function* createEffectStreamGen(
    source: AsyncIterable<Data>
  ) {
    for await (const chunk of source) {
      effectFn(chunk)
      yield chunk
    }
  }

  // context(justinvdm: 28 Sep 2022): @types/node do not have a typedef for the arity we have here
  // the includes async generators:
  // https://github.com/snaplet/snaplet/pull/1400#discussion_r982184327
  return gen as unknown as NodeJS.ReadWriteStream
}
