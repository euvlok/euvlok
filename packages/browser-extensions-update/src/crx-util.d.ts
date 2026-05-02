declare module 'crx-util' {
  const crx: {
    parser: {
      isCrx(crxPathOrBuffer: string | Buffer): boolean;
      getCrxVersion(crxPathOrBuffer: string | Buffer): number;
      getZipContents(crxPathOrBuffer: string | Buffer): Buffer;
    };
  };

  export default crx;
}
