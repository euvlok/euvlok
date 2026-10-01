declare module "usercss-meta" {
  export interface Variable {
    type: string;
    name: string;
    label: string;
    value: unknown;
    default: unknown;
    options?: { name: string; label: string; value?: string }[];
  }

  export interface Metadata {
    name: string;
    namespace: string;
    version: string;
    preprocessor?: string;
    description?: string;
    author?: string;
    url?: string;
    updateURL?: string;
    vars?: Record<string, Variable>;
    [key: string]: unknown;
  }

  const usercssMeta: {
    parse(source: string): { metadata: Metadata };
    stringify(metadata: Metadata): string;
  };
  export default usercssMeta;
}
