import { type ConsolaInstance, consola } from 'consola';

export const logger: ConsolaInstance = consola.create({
  formatOptions: {
    date: false,
  },
});

export { consola };
