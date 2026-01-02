import fs from 'fs';
import archiver from 'archiver';
import path from 'path';

const output = fs.createWriteStream(path.join(process.cwd(), 'deploy.zip'));
const archive = archiver('zip', {
  zlib: { level: 9 }
});

output.on('close', () => {
  console.log(`${archive.pointer()} total bytes`);
  console.log('archiver has been finalized and the output file descriptor has closed.');
});

archive.on('warning', (err) => {
  if (err.code === 'ENOENT') {
    console.warn(err);
  } else {
    throw err;
  }
});

archive.on('error', (err) => {
  throw err;
});

archive.pipe(output);

// Add files and directories, excluding certain patterns
archive.glob('**/*', {
  ignore: [
    'deploy.zip',
    'pack.js',
    '.git/**',
    'main.tf',
    'terraform/**',
    'node_modules/**', // Usually we don't want node_modules in the zip for EB if we do npm install on the server
  ]
});

await archive.finalize();
