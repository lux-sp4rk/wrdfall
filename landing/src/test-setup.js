import '@testing-library/jest-dom'

// Node.js v25+ exposes a native localStorage global that has no .clear() method.
// The jsdom environment exposes its own Storage instance via window.jsdom.window.localStorage.
// We override globalThis.localStorage with jsdom's working implementation here.
if (typeof globalThis.jsdom !== 'undefined') {
  const jsdomLocalStorage = globalThis.jsdom.window.localStorage
  const jsdomSessionStorage = globalThis.jsdom.window.sessionStorage
  Object.defineProperty(globalThis, 'localStorage', {
    get: () => jsdomLocalStorage,
    configurable: true,
  })
  Object.defineProperty(globalThis, 'sessionStorage', {
    get: () => jsdomSessionStorage,
    configurable: true,
  })
}
