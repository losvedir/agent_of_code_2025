import { readInput, readLines } from '../utils/input.js';

export function part1(input: string): number {
  const lines = input.split('\n');
  // TODO: Implement part 1
  return 0;
}

export function part2(input: string): number {
  const lines = input.split('\n');
  // TODO: Implement part 2
  return 0;
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  const input = readInput(import.meta.url);
  console.log('Part 1:', part1(input));
  console.log('Part 2:', part2(input));
}
