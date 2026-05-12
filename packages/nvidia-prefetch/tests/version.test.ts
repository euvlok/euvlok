import { describe, expect, test } from 'bun:test';
import { compareNvidiaVersions, findLatestSharedNvidiaVersion } from '../src/version';

describe('NVIDIA version selection', () => {
  test('accepts and sorts NVIDIA versions with leading-zero components', () => {
    const versions = ['580.126.18', '595.71.05', '575.64.05'];

    expect(versions.toSorted(compareNvidiaVersions)).toEqual(['575.64.05', '580.126.18', '595.71.05']);
  });

  test('selects the newest common version without downgrading because semver rejected it', () => {
    expect(findLatestSharedNvidiaVersion(['580.126.18', '595.71.05'], ['575.64.05', '580.126.18', '595.71.05'])).toBe(
      '595.71.05',
    );
  });
});
