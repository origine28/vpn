import type { FastifyInstance } from 'fastify';

import { getPrisma } from '../db.js';

export async function serverRoutes(app: FastifyInstance): Promise<void> {
  app.get('/countries/:countryCode/servers', async (request, reply) => {
    const { countryCode } = request.params as { countryCode: string };

    const prisma = getPrisma();

    const country = await prisma.country.findUnique({
      where: { code: countryCode.toUpperCase() },
    });

    if (!country) {
      return reply.status(404).send({
        error: 'Country not found',
        message: `Aucun pays trouvé pour le code ${countryCode}`,
      });
    }

    const servers = await prisma.vpnServer.findMany({
      where: {
        countryId: country.id,
        isActive: true,
      },
      include: {
        provider: {
          select: { name: true },
        },
      },
    });

    return {
      country: {
        code: country.code,
        name: country.name,
        flag: country.flag,
      },
      servers: servers.map((s) => ({
        id: s.id,
        name: s.name,
        provider: s.provider.name,
      })),
    };
  });
}
