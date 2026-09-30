// Runs the exact JavaScript used by JavaScriptBridge; no browser automation.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync(path.join(__dirname, '../assets/browser_storage.gd'), 'utf8').split('"""')[1];
const saved = new Map();
const storage = {getItem: k => saved.get(k) ?? null, setItem: (k,v) => saved.set(k,v)};
function bridge(localStorage) { const c = vm.createContext({localStorage}); vm.runInContext(source,c); return c; }
let context = bridge(storage);
const raw = JSON.stringify({name:'测试 "quoted"\n</script>', parameters:{seed:42}});
assert.equal(JSON.parse(vm.runInContext('PixelCosmosStorage.write('+JSON.stringify(raw)+')',context)).ok,true);
context = bridge(storage); // New page context, same browser storage.
assert.equal(JSON.parse(vm.runInContext('PixelCosmosStorage.read()',context)).value,raw);
for (const name of ['SecurityError','QuotaExceededError']) {
  const failed = bridge({getItem(){throw Error(name)},setItem(){throw Error(name)}});
  assert.equal(JSON.parse(vm.runInContext('PixelCosmosStorage.read()',failed)).ok,false);
  assert.equal(JSON.parse(vm.runInContext('PixelCosmosStorage.write("x")',failed)).ok,false);
}
assert.equal(saved.get('pixel-cosmos-studio.library.v1'),raw);
console.log('BROWSER_STORAGE_TEST_OK: reload, escaped JSON, blocked storage, quota errors');
