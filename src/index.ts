import Koa from 'koa';
import Router from '@koa/router';
import fs from 'node:fs/promises';
import path from 'node:path';

const app = new Koa();
const router = new Router();

router.get('/', (ctx) => {
  ctx.body = 'Hello, world!';
});

router.get('/node_modules', async (ctx) => {
  const nodeModulesPath = path.resolve('node_modules');
  const files = await fs.readdir(nodeModulesPath);
  const stats = await Promise.all(
    files.map(async (file) => {
      const s = await fs.stat(path.join(nodeModulesPath, file));
      return `${file} (${s.mtime.toISOString()})`;
    })
  );
  ctx.body = stats.join('\n');
});

router.get('/package.json', async (ctx) => {
  const packageJsonPath = path.resolve('package.json');
  ctx.body = await fs.readFile(packageJsonPath, 'utf-8');
  ctx.type = 'application/json';
});

app.use(router.routes()).use(router.allowedMethods());

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
