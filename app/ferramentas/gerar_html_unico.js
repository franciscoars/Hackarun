// Gera um HTML único e independente com o app Flutter inteiro embutido.
// Uso: node gerar.js <pasta-do-build> <saida.html> <fonte.woff2>...
const fs = require('fs');
const path = require('path');

const [build, saida, ...fontes] = process.argv.slice(2);
const tipos = {
  '.json': 'application/json', '.otf': 'font/otf', '.ttf': 'font/ttf',
  '.jpg': 'image/jpeg', '.png': 'image/png', '.woff2': 'font/woff2',
};

function listar(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const p = path.join(dir, e.name);
    return e.isDirectory() ? listar(p) : [p];
  });
}

const arquivos = {};
for (const f of listar(path.join(build, 'assets'))) {
  const chave = path.relative(build, f).split(path.sep).join('/');
  if (chave.endsWith('.gitkeep') || chave.endsWith('NOTICES')) continue;
  arquivos[chave] = {
    t: tipos[path.extname(f)] || 'application/octet-stream',
    d: fs.readFileSync(f).toString('base64'),
  };
}
// Fontes que o motor baixaria do Google Fonts (Roboto e símbolos do totem).
for (const f of fontes) arquivos[path.basename(f)] = { t: 'font/woff2', d: fs.readFileSync(f).toString('base64') };

const wasm = fs.readFileSync(path.join(build, 'canvaskit', 'canvaskit.wasm')).toString('base64');
const canvaskit = fs.readFileSync(path.join(build, 'canvaskit', 'canvaskit.js'), 'utf8')
  .replace('export default CanvasKitInit;', '');
const app = fs.readFileSync(path.join(build, 'main.dart.js'), 'utf8');
for (const [nome, txt] of [['canvaskit', canvaskit], ['main', app]]) {
  if (/<\/script/i.test(txt)) throw new Error(`${nome} contém </script>`);
}

const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#17382A">
<title>Guia Acessível · Capim Dourado Shopping</title>
<style>
  html, body { margin: 0; height: 100%; background: #0C1C14; overflow: hidden; }
  #carregando { position: fixed; inset: 0; display: flex; flex-direction: column; align-items: center;
    justify-content: center; gap: 14px; color: #F6E3C8; font: 600 16px system-ui, sans-serif; background: #676E4F; }
  #carregando i { width: 44px; height: 44px; border: 4px solid #F6E3C855; border-top-color: #F2C14E;
    border-radius: 50%; animation: gira 0.9s linear infinite; }
  @keyframes gira { to { transform: rotate(360deg); } }
</style>
</head>
<body>
<div id="carregando"><i></i>Carregando o Guia Acessível…</div>
<script>
// Arquivos do app (fontes, logo, manifestos) embutidos: nada é baixado da internet.
(function () {
  var A = ${JSON.stringify(arquivos)};
  var chaves = Object.keys(A).sort(function (a, b) { return b.length - a.length; });
  var cache = {};
  function bytes(b64) {
    var s = atob(b64), u = new Uint8Array(s.length);
    for (var i = 0; i < s.length; i++) u[i] = s.charCodeAt(i);
    return u;
  }
  var fetchOriginal = window.fetch.bind(window);
  window.fetch = function (rec, opc) {
    var url = typeof rec === 'string' ? rec : (rec && rec.url) || String(rec);
    var caminho = decodeURIComponent(url.split('?')[0].split('#')[0]);
    for (var i = 0; i < chaves.length; i++) {
      var k = chaves[i];
      if (caminho === k || caminho.slice(-k.length - 1) === '/' + k) {
        var a = A[k];
        cache[k] = cache[k] || bytes(a.d);
        return Promise.resolve(new Response(cache[k].slice(), {
          status: 200, headers: { 'Content-Type': a.t },
        }));
      }
    }
    return fetchOriginal(rec, opc);
  };
  // O motor gráfico (CanvasKit) é iniciado pelo módulo abaixo.
  window.flutterCanvasKitLoaded = new Promise(function (ok) { window.__ckPronto = ok; });
  window.__wasmBytes = bytes;
})();
</script>
<script type="module">
${canvaskit}
const wasm = window.__wasmBytes(${JSON.stringify(wasm)});
CanvasKitInit({
  // Instancia o WebAssembly a partir dos bytes embutidos (sem baixar canvaskit.wasm).
  instantiateWasm: (imports, pronto) => {
    WebAssembly.instantiate(wasm, imports).then((r) => pronto(r.instance, r.module));
    return {};
  },
}).then((ck) => {
  window.flutterCanvasKit = ck;
  window.__ckPronto(ck);
  const msg = document.getElementById('carregando');
  if (msg) setTimeout(() => msg.remove(), 600);
});
</script>
<script>
${app}
</script>
</body>
</html>
`;
fs.mkdirSync(path.dirname(saida), { recursive: true });
fs.writeFileSync(saida, html);
console.log(`${saida}: ${(Buffer.byteLength(html) / 1048576).toFixed(1)} MB, ${Object.keys(arquivos).length} arquivos embutidos`);
