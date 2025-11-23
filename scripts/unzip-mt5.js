const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

const mt5Dir = path.join(__dirname, '..', 'terminal', 'mt5');
const zipFiles = [
  { zip: 'terminal64.zip', exe: 'terminal64.exe' },
  { zip: 'MetaEditor64.zip', exe: 'MetaEditor64.exe' }
];

console.log('Checking MT5 executables...');

function unzipFile(zipPath, destDir) {
  const platform = os.platform();
  
  if (platform === 'win32') {
    // Windows: Use PowerShell
    execSync(`powershell -Command "Expand-Archive -Path '${zipPath}' -DestinationPath '${destDir}' -Force"`, {
      stdio: 'inherit'
    });
  } else {
    // Linux/macOS: Use unzip command
    execSync(`unzip -o "${zipPath}" -d "${destDir}"`, {
      stdio: 'inherit'
    });
  }
}

zipFiles.forEach(({ zip, exe }) => {
  const zipPath = path.join(mt5Dir, zip);
  const exePath = path.join(mt5Dir, exe);
  
  if (!fs.existsSync(zipPath)) {
    console.log(`⚠️  ${zip} not found, skipping...`);
    return;
  }
  
  if (fs.existsSync(exePath)) {
    console.log(`✓ ${exe} already exists, skipping extraction`);
    return;
  }
  
  console.log(`Extracting ${zip}...`);
  try {
    unzipFile(zipPath, mt5Dir);
    console.log(`✓ ${exe} extracted successfully`);
  } catch (error) {
    console.error(`✗ Failed to extract ${zip}:`, error.message);
    process.exit(1);
  }
});

console.log('Done!');
