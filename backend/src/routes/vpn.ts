import type { FastifyInstance } from 'fastify';

import { getPrisma } from '../db.js';
import { ProviderRegistry } from '../services/provider-registry.js';
import { VpnOrchestratorService } from '../services/vpn-orchestrator.js';
import { createDemoProviderA, createDemoProviderB } from '../services/demo-providers.js';

// WireGuard server configuration from environment variables
// In development, defaults to demo values (SIMULATION mode)
// In production, set these to real WireGuard server values
const WIREGUARD_SERVER_PUBLIC_KEY = process.env.WIREGUARD_SERVER_PUBLIC_KEY ?? '';
const WIREGUARD_ENDPOINT = process.env.WIREGUARD_ENDPOINT ?? '';
const WIREGUARD_DNS = process.env.WIREGUARD_DNS ?? '1.1.1.1';
const WIREGUARD_CLIENT_ADDRESS = process.env.WIREGUARD_CLIENT_ADDRESS ?? '10.8.0.2/32';

const isSimulationMode = !WIREGUARD_SERVER_PUBLIC_KEY || !WIREGUARD_ENDPOINT;

async function buildRegistry(): Promise<ProviderRegistry> {
  const prisma = getPrisma();

  const [dbProviders, dbServers] = await Promise.all([
    prisma.vpnProvider.findMany({ where: { isActive: true } }),
    prisma.vpnServer.findMany({
      where: { isActive: true },
      include: { country: { select: { id: true } } },
    }),
  ]);

  const registry = new ProviderRegistry();

  for (const dbProvider of dbProviders) {
    const providerServers = dbServers
      .filter((s) => s.providerId === dbProvider.id)
      .map((s) => ({
        id: s.id,
        name: s.name,
        countryId: s.countryId,
        providerName: dbProvider.name,
      }));

    if (dbProvider.name === 'DemoProviderA') {
      registry.register(createDemoProviderA(providerServers));
    } else if (dbProvider.name === 'DemoProviderB') {
      registry.register(createDemoProviderB(providerServers));
    }
  }

  return registry;
}

const activeConnections = new Map<string, {
  connectionId: string;
  serverId: string;
  serverName: string;
  countryCode: string;
  providerName: string;
  protocol: string;
  status: string;
  clientPublicKey: string;
  expiresAt: Date;
  createdAt: Date;
}>();

export async function vpnRoutes(app: FastifyInstance): Promise<void> {
  app.post('/vpn/connect', async (request, reply) => {
    const body = request.body as {
      countryCode?: string;
      clientPublicKey?: string;
    };

    if (!body.countryCode || typeof body.countryCode !== 'string') {
      return reply.status(400).send({
        error: 'Bad request',
        message: 'countryCode est requis',
      });
    }

    if (!body.clientPublicKey || typeof body.clientPublicKey !== 'string') {
      return reply.status(400).send({
        error: 'Bad request',
        message: 'clientPublicKey est requis (clé publique WireGuard du client)',
      });
    }

    const countryCode = body.countryCode.toUpperCase();
    const clientPublicKey = body.clientPublicKey;
    const prisma = getPrisma();

    const country = await prisma.country.findUnique({
      where: { code: countryCode },
    });

    if (!country) {
      return reply.status(404).send({
        error: 'Country not found',
        message: `Aucun pays trouvé pour le code ${countryCode}`,
      });
    }

    const registry = await buildRegistry();
    const orchestrator = new VpnOrchestratorService(registry);

    const result = orchestrator.selectServer(country.id);

    if (!result) {
      return reply.status(404).send({
        error: 'No server available',
        message: `Aucun serveur disponible pour ${country.name}`,
      });
    }

    const connectionId = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);

    const connection = {
      connectionId,
      serverId: result.server.id,
      serverName: result.server.name,
      countryCode,
      providerName: result.providerName,
      protocol: result.config.protocol,
      status: 'READY',
      clientPublicKey,
      expiresAt,
      createdAt: new Date(),
    };

    activeConnections.set(connectionId, connection);

    return {
      connectionId,
      country: countryCode,
      server: {
        id: result.server.id,
        name: result.server.name,
      },
      protocol: result.config.protocol,
      status: connection.status,
      expiresAt: expiresAt.toISOString(),
      wireguard: {
        serverPublicKey: WIREGUARD_SERVER_PUBLIC_KEY || 'SIMULATION_MODE',
        serverEndpoint: WIREGUARD_ENDPOINT || 'simulation.wireguard.local:51820',
        allowedIPs: ['0.0.0.0/0'],
        dnsServer: WIREGUARD_DNS,
        clientAddress: WIREGUARD_CLIENT_ADDRESS,
        mtu: 1420,
      },
      mode: isSimulationMode ? 'SIMULATION' : 'LIVE',
    };
  });

  app.post('/vpn/disconnect', async (request, reply) => {
    const body = request.body as { connectionId?: string };

    if (!body.connectionId || typeof body.connectionId !== 'string') {
      return reply.status(400).send({
        error: 'Bad request',
        message: 'connectionId est requis',
      });
    }

    const connection = activeConnections.get(body.connectionId);

    if (!connection) {
      return reply.status(404).send({
        error: 'Connection not found',
        message: 'Connexion non trouvée ou déjà déconnectée',
      });
    }

    activeConnections.delete(body.connectionId);

    return {
      connectionId: body.connectionId,
      status: 'DISCONNECTED',
    };
  });
}
