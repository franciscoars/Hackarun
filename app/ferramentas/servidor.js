// Servidor estático para o build web, acessível pela rede local (para o QR Code do totem).
// Uso: node ferramentas/servidor.js [porta]
const http = require('http');
const fs = require('fs');
const path = require('path');

const RAIZ = path.join(__dirname, '..', 'build', 'web');
const PORTA = Number(process.argv[2] || 8090);
const TIPOS = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.mjs': 'application/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png', '.webp': 'image/webp',
  '.otf': 'font/otf', '.ttf': 'font/ttf', '.frag': 'application/octet-stream', '.bin': 'application/octet-stream',
};

http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p.endsWith('/')) p += 'index.html';
  const arquivo = path.normalize(path.join(RAIZ, p));
  if (!arquivo.startsWith(RAIZ)) { res.writeHead(403); return res.end(); }
  fs.readFile(arquivo, (err, dados) => {
    if (err) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'Content-Type': TIPOS[path.extname(arquivo)] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
    res.end(dados);
  });
}).listen(PORTA, '0.0.0.0', () => console.log(`Servindo ${RAIZ} em http://0.0.0.0:${PORTA}`));
