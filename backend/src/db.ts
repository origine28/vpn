import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from './generated/prisma/client.js';

let prisma: PrismaClient | null = null;

export function getPrisma(): PrismaClient {
  if (!prisma) {
    const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
    prisma = new PrismaClient({ adapter });
  }
  return prisma;
}

export async function closePrisma(): Promise<void> {
  if (prisma) {
    await prisma.$disconnect();
    prisma = null;
  }
}
