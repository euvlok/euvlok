import { Listr } from 'listr2';
import { group } from './logging';

export async function runSequentialTasks<T>(
  items: readonly T[],
  title: (item: T) => string,
  task: (item: T) => Promise<void>,
): Promise<void> {
  const tasks = new Listr(
    items.map((item) => {
      const taskTitle = title(item);
      return {
        title: taskTitle,
        task: () => group(`Processing ${taskTitle}`, () => task(item)),
      };
    }),
    { concurrent: false, exitOnError: false },
  );

  await tasks.run();
}
