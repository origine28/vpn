import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z
    .string()
    .default('postgresql://postgres:postgres@localhost:5432/vpn'),
  CORS_ORIGIN: z.string().default('*'),
});

export type Env = z.infer<typeof envSchema>;

export const env: Env = envSchema.parse(process.env);
