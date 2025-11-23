const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// MQL source files to check for compilation
const MQL_FILES = [
  { source: 'terminal/mt4/MQL4/Scripts/fxcloud.mq4', compiled: 'terminal/mt4/MQL4/Scripts/fxcloud.ex4' },
  { source: 'terminal/mt5/MQL5/Services/fxcloud.mq5', compiled: 'terminal/mt5/MQL5/Services/fxcloud.ex5' }
];

const TERMINAL_DIRS = [
  'terminal/mt4/MQL4',
  'terminal/mt5/MQL5'
];

function findCompiledFiles(dir, extensions) {
  const files = [];
  
  function walk(currentPath) {
    if (!fs.existsSync(currentPath)) return;
    
    const items = fs.readdirSync(currentPath);
    for (const item of items) {
      const fullPath = path.join(currentPath, item);
      const stat = fs.statSync(fullPath);
      
      if (stat.isDirectory()) {
        walk(fullPath);
      } else if (extensions.some(ext => item.endsWith(ext))) {
        files.push(fullPath);
      }
    }
  }
  
  walk(dir);
  return files;
}

function cleanup() {
  console.log('🧹 Cleaning up compiled files...');
  let cleanedCount = 0;
  
  for (const dir of TERMINAL_DIRS) {
    if (!fs.existsSync(dir)) continue;
    
    const compiledFiles = findCompiledFiles(dir, ['.ex4', '.ex5']);
    
    for (const file of compiledFiles) {
      try {
        fs.unlinkSync(file);
        console.log(`  ✓ Deleted: ${file}`);
        cleanedCount++;
      } catch (err) {
        console.warn(`  ⚠ Failed to delete ${file}: ${err.message}`);
      }
    }
  }
  
  console.log(`📦 Cleaned ${cleanedCount} compiled file(s)\n`);
}

function compile() {
  console.log('🔨 Compiling MQL files...');
  try {
    execSync('docker compose -f compile.yml up', { 
      stdio: 'inherit',
      cwd: process.cwd()
    });
    console.log('✓ Compilation command completed\n');
    return true;
  } catch (err) {
    console.error('✗ Compilation command failed:', err.message);
    return false;
  }
}

function verifyCompilation() {
  console.log('🔍 Verifying compilation results...');
  
  const results = MQL_FILES.map(({ source, compiled }) => {
    const exists = fs.existsSync(compiled);
    return {
      source: source,
      compiled: compiled,
      success: exists
    };
  });
  
  console.log('\nCompilation Results:');
  console.log('═'.repeat(80));
  
  let allSuccess = true;
  for (const result of results) {
    const status = result.success ? '✓' : '✗';
    const statusText = result.success ? 'SUCCESS' : 'FAILED';
    console.log(`${status} ${statusText.padEnd(8)} ${result.source}`);
    console.log(`  ${result.success ? '→' : '✗'} ${result.compiled}`);
    
    if (!result.success) {
      allSuccess = false;
    }
  }
  
  console.log('═'.repeat(80));
  
  if (allSuccess) {
    console.log('\n✅ All files compiled successfully!');
  } else {
    console.log('\n❌ Some files failed to compile!');
  }
  
  return allSuccess;
}

function main() {
  console.log('🚀 Starting MQL Compilation Process\n');
  
  // Step 1: Cleanup
  cleanup();
  
  // Step 2: Compile
  const compileSuccess = compile();
  if (!compileSuccess) {
    console.error('\n❌ Compilation process failed!');
    process.exit(1);
  }
  
  // Step 3: Verify
  const verifySuccess = verifyCompilation();
  
  if (!verifySuccess) {
    process.exit(1);
  }
}

main();
