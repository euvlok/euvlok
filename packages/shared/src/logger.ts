import { consola, type ConsolaInstance } from 'consola';

export const logger: ConsolaInstance = consola.create({
  formatOptions: {
    date: false,
  },
});

export { consola };
