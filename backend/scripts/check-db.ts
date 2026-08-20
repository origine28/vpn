import 'dotenv/config';
import pg from 'pg';

const { Client } = pg;

async function main(): Promise<void> {
  const url = process.env.DATABASE_URL;
  if (!url) {
    console.error('DATABASE_URL absente : copiez backend/.env.example vers backend/.env');
    process.exit(1);
  }

  const client = new Client({ connectionString: url });
  await client.connect();
  const result = await client.query('SELECT 1 AS ok');
  console.log(`PostgreSQL accessible : ${result.rows[0].ok}`);
  await client.end();
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Échec de connexion PostgreSQL : ${message}`);
  process.exit(1);
});
