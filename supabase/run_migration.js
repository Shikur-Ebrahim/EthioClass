#!/usr/bin/env node
// Auto-runs the Supabase schema migration via the Management API
// Uses the service_role key to bypass RLS for schema creation

const https = require('https');
const fs = require('fs');
const path = require('path');

// â”€â”€ Config from backend/.env â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const SUPABASE_URL = 'https://ogbwhbzptrzjdetyygxt.supabase.co';
const SUPABASE_SERVICE_KEY = 'REMOVED_FOR_SECURITY';
const SQL_FILE = path.join(__dirname, '../supabase/migrations/001_initial_schema.sql');

const sql = fs.readFileSync(SQL_FILE, 'utf-8');

// Split into individual statements (skip comments and blank lines)
const statements = sql
  .split(';')
  .map(s => s.trim())
  .filter(s => s.length > 0 && !s.startsWith('--'));

console.log(`Found ${statements.length} SQL statements to execute...`);

async function runSQL(sqlStatement) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ query: sqlStatement + ';' });
    const url = new URL(`${SUPABASE_URL}/rest/v1/rpc/query`);

    const options = {
      hostname: url.hostname,
      path: '/rest/v1/rpc/query',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Length': Buffer.byteLength(body),
        'Prefer': 'return=minimal'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  // Use the pg connection string approach via Supabase's SQL API
  const projectRef = 'ogbwhbzptrzjdetyygxt';
  const managementApiUrl = `https://api.supabase.com/v1/projects/${projectRef}/database/query`;

  console.log('Running schema migration via Supabase API...\n');

  // Run all statements at once via the management endpoint
  const body = JSON.stringify({ query: sql });

  const options = {
    hostname: 'api.supabase.com',
    path: `/v1/projects/${projectRef}/database/query`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Length': Buffer.byteLength(body),
    }
  };

  const result = await new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });

  if (result.status === 200 || result.status === 201) {
    console.log('âœ… Schema migration applied successfully!');
    console.log('Response:', result.body);
  } else {
    console.log(`Status: ${result.status}`);
    console.log('Response:', result.body);
    // Try alternative approach using PostgREST RPC
    console.log('\nTrying alternative approach via PostgREST...');
    await runViaPostgrest();
  }
}

async function runViaPostgrest() {
  // Split and run statements one by one
  for (let i = 0; i < statements.length; i++) {
    const stmt = statements[i];
    if (!stmt || stmt.startsWith('--')) continue;

    process.stdout.write(`Running statement ${i + 1}/${statements.length}... `);

    const body = JSON.stringify({ query: stmt });
    const result = await new Promise((resolve, reject) => {
      const req = https.request({
        hostname: 'ogbwhbzptrzjdetyygxt.supabase.co',
        path: '/rest/v1/rpc/exec_sql',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Length': Buffer.byteLength(body),
        }
      }, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => resolve({ status: res.statusCode, body: data }));
      });
      req.on('error', reject);
      req.write(body);
      req.end();
    });

    if (result.status < 300) {
      console.log('âœ…');
    } else {
      console.log(`âš ï¸  ${result.status} - ${result.body.substring(0, 100)}`);
    }
  }
}

main().catch(console.error);
