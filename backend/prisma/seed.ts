import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

const countries = [
  { code: 'FR', name: 'France', flag: '🇫🇷' },
  { code: 'DE', name: 'Allemagne', flag: '🇩🇪' },
  { code: 'US', name: 'États-Unis', flag: '🇺🇸' },
  { code: 'GB', name: 'Royaume-Uni', flag: '🇬🇧' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦' },
  { code: 'NL', name: 'Pays-Bas', flag: '🇳🇱' },
];

const providers = [
  { name: 'DemoProviderA', priority: 1 },
  { name: 'DemoProviderB', priority: 2 },
];

const servers: { name: string; countryCode: string; providerName: string }[] = [
  { name: 'demo-fr-01', countryCode: 'FR', providerName: 'DemoProviderA' },
  { name: 'demo-fr-02', countryCode: 'FR', providerName: 'DemoProviderB' },
  { name: 'demo-de-01', countryCode: 'DE', providerName: 'DemoProviderA' },
  { name: 'demo-de-02', countryCode: 'DE', providerName: 'DemoProviderB' },
  { name: 'demo-us-01', countryCode: 'US', providerName: 'DemoProviderA' },
  { name: 'demo-us-02', countryCode: 'US', providerName: 'DemoProviderB' },
  { name: 'demo-gb-01', countryCode: 'GB', providerName: 'DemoProviderA' },
  { name: 'demo-gb-02', countryCode: 'GB', providerName: 'DemoProviderB' },
  { name: 'demo-ca-01', countryCode: 'CA', providerName: 'DemoProviderA' },
  { name: 'demo-ca-02', countryCode: 'CA', providerName: 'DemoProviderB' },
  { name: 'demo-nl-01', countryCode: 'NL', providerName: 'DemoProviderA' },
  { name: 'demo-nl-02', countryCode: 'NL', providerName: 'DemoProviderB' },
];

async function main() {
  console.log('Seeding database...');

  for (const country of countries) {
    await prisma.country.upsert({
      where: { code: country.code },
      update: { name: country.name, flag: country.flag },
      create: country,
    });
  }
  console.log(`  ✓ ${countries.length} countries seeded`);

  for (const provider of providers) {
    await prisma.vpnProvider.upsert({
      where: { name: provider.name },
      update: { priority: provider.priority, isActive: true },
      create: provider,
    });
  }
  console.log(`  ✓ ${providers.length} providers seeded`);

  for (const server of servers) {
    const country = await prisma.country.findUnique({ where: { code: server.countryCode } });
    const provider = await prisma.vpnProvider.findUnique({ where: { name: server.providerName } });
    if (country && provider) {
      await prisma.vpnServer.upsert({
        where: { name: server.name },
        update: { isActive: true },
        create: {
          name: server.name,
          countryId: country.id,
          providerId: provider.id,
        },
      });
    }
  }
  console.log(`  ✓ ${servers.length} servers seeded`);

  console.log('Seeding complete!');
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
