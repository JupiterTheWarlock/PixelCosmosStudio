extends RefCounted

# A small synchronous JSON library: browser quota/security errors must be visible.
# eval receives JSON.stringify-style literals, never interpolated raw user text.
const SOURCE = """
var PixelCosmosStorage = {
 key: 'pixel-cosmos-studio.library.v1',
 read: function() {
  try { return JSON.stringify({ok:true,value:localStorage.getItem(this.key)||''}); }
  catch(e) { return JSON.stringify({ok:false,error:String(e)}); }
 },
 write: function(value) {
  try {
   localStorage.setItem(this.key,value);
   if(localStorage.getItem(this.key)!==value) throw new Error('Storage verification failed');
   return JSON.stringify({ok:true});
  } catch(e) { return JSON.stringify({ok:false,error:String(e)}); }
 }
};
"""
