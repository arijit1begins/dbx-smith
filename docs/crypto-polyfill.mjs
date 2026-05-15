import { webcrypto } from 'node:crypto';
if (!globalThis.crypto) {
  globalThis.crypto = webcrypto;
}
// Also define 'crypto' in the global scope for packages that use it as a bare identifier
if (typeof crypto === 'undefined') {
  Object.defineProperty(globalThis, 'crypto', {
    value: webcrypto,
    writable: true,
    enumerable: false,
    configurable: true,
  });
}
