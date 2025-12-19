import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

export function readInput(importMetaUrl: string): string {
  const currentDir = dirname(fileURLToPath(importMetaUrl));
  return readFileSync(join(currentDir, 'input.txt'), 'utf-8').trim();
}

export function readLines(importMetaUrl: string): string[] {
  return readInput(importMetaUrl).split('\n');
}
