import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));
if (existsSync(resolve(root, '.env'))) process.loadEnvFile(resolve(root, '.env'));
const mode = process.argv[2] || 'dev';
if (mode === 'e2e') {
  const url = process.env.KUSAKARI_E2E_DB_URL;
  if (!url || !/^jdbc:mysql:\/\/127\.0\.0\.1:3306\/kusakari_e2e(?:\?|$)/.test(url)) {
    throw new Error('E2E requires the dedicated kusakari_e2e database on 127.0.0.1:3306.');
  }
  process.env.KUSAKARI_DB_URL = url;
  process.env.KUSAKARI_API_PORT = '18086';
  process.env.KUSAKARI_WEB_ORIGIN = 'http://127.0.0.1:15186';
}
const build = mode === 'build';
const windowsBuild = build && process.platform === 'win32';
const command = build ? (windowsBuild ? 'mvnw.cmd -B -ntp package -DskipTests' : './mvnw') : 'java';
const args = build
  ? windowsBuild
    ? []
    : ['-B', '-ntp', 'package', '-DskipTests']
  : ['-jar', 'target/kusakari-api-0.1.0.jar'];
const child = spawn(command, args, {
  cwd: resolve(root, 'backend'),
  stdio: 'inherit',
  shell: build && process.platform === 'win32',
});
child.on('error', (error) => {
  console.error(error.message);
  process.exitCode = 1;
});
child.on('exit', (code) => {
  process.exitCode = code ?? 1;
});
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => child.kill(signal));
