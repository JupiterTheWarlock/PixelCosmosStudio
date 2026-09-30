extends RefCounted

const SOURCE="""
window.PixelCosmosFiles = window.PixelCosmosFiles || {
  pickJson(callback) {
    const input = document.createElement('input');
    input.type = 'file'; input.accept = '.json,application/json'; input.style.display = 'none';
    let finished = false;
    const finish = result => {
      if (finished) return;
      finished = true; input.remove(); callback(JSON.stringify(result));
    };
    input.addEventListener('cancel', () => finish({cancelled:true}), {once:true});
    input.addEventListener('change', async () => {
      const file = input.files[0];
      if (!file) return finish({cancelled:true});
      if (file.size > 2 * 1024 * 1024) return finish({error:'too_large'});
      try { finish({text:await file.text()}); }
      catch (_) { finish({error:'read_failed'}); }
    }, {once:true});
    document.body.appendChild(input);
    try { input.click(); } catch (_) { finish({error:'read_failed'}); }
  },
  showText(text, title, instructions, copyLabel, copiedLabel, closeLabel) {
    const prior = document.getElementById('cosmos-copy-dialog');
    if (prior) prior.remove();
    const dialog = document.createElement('dialog'); dialog.id = 'cosmos-copy-dialog';
    dialog.style.cssText = 'background:#08141e;color:#f6d6bd;border:1px solid #c3a38a;width:min(820px,88vw);padding:20px;font:16px sans-serif';
    const heading = document.createElement('h2'); heading.textContent = title;
    const hint = document.createElement('p'); hint.textContent = instructions;
    const area = document.createElement('textarea'); area.value = text; area.readOnly = true;
    area.style.cssText = 'box-sizing:border-box;width:100%;height:50vh;background:#0f2a3f;color:#f6d6bd;border:1px solid #c3a38a;padding:12px;font:14px monospace';
    const copy = document.createElement('button'); copy.textContent = copyLabel;
    copy.onclick = async () => {
      area.focus(); area.select();
      try { await navigator.clipboard.writeText(text); hint.textContent = copiedLabel; }
      catch (_) { hint.textContent = instructions; }
    };
    const close = document.createElement('button'); close.textContent = closeLabel;
    close.onclick = () => dialog.close();
    for (const button of [copy,close]) button.style.cssText = 'margin:12px 12px 0 0;padding:8px 16px;background:#c3a38a;color:#08141e;border:1px solid #f6d6bd;font:inherit';
    dialog.append(heading,hint,area,copy,close);
    dialog.addEventListener('close', () => dialog.remove(), {once:true});
    document.body.appendChild(dialog); dialog.showModal(); area.focus(); area.select();
  }
};
"""
