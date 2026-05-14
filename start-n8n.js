import { spawn, exec } from 'child_process';
import { createConnection } from 'net';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = 5678;
const APP_URL = `http://localhost:${PORT}`;

const isPortOpen = () => new Promise(resolve => {
  const s = createConnection(PORT, 'localhost');
  s.on('connect', () => { s.destroy(); resolve(true); });
  s.on('error',   () => { s.destroy(); resolve(false); });
});

const waitForPort = (timeout = 30) => new Promise((resolve, reject) => {
  let tries = 0;
  const check = () => isPortOpen().then(open => {
    if (open) resolve();
    else if (++tries >= timeout) reject(new Error(`n8n did not start within ${timeout}s. Check for errors.`));
    else setTimeout(check, 1000);
  });
  check();
});

if (await isPortOpen()) {
  console.log('n8n is already running. Opening UI...');
} else {
  console.log('Starting n8n...');
  spawn('n8n', ['start'], { detached: true, stdio: 'ignore', shell: true, cwd: __dirname }).unref();
  await waitForPort().catch(e => { console.error(e.message); process.exit(1); });
  console.log(`n8n is up at ${APP_URL}`);
}

const opener = { win32: 'start', darwin: 'open' }[process.platform] ?? 'xdg-open';
exec(`${opener} ${APP_URL}`);

