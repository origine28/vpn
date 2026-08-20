-- CreateTable
CREATE TABLE "Country" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "flag" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Country_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VpnProvider" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VpnProvider_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VpnServer" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "countryId" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VpnServer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VpnConnection" (
    "id" TEXT NOT NULL,
    "serverId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'READY',
    "protocol" TEXT NOT NULL DEFAULT 'DEMO',
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VpnConnection_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Country_code_key" ON "Country"("code");

-- CreateIndex
CREATE UNIQUE INDEX "VpnProvider_name_key" ON "VpnProvider"("name");

-- CreateIndex
CREATE INDEX "VpnServer_countryId_idx" ON "VpnServer"("countryId");

-- CreateIndex
CREATE INDEX "VpnServer_providerId_idx" ON "VpnServer"("providerId");

-- CreateIndex
CREATE UNIQUE INDEX "VpnServer_name_key" ON "VpnServer"("name");

-- CreateIndex
CREATE INDEX "VpnConnection_serverId_idx" ON "VpnConnection"("serverId");

-- CreateIndex
CREATE INDEX "VpnConnection_status_idx" ON "VpnConnection"("status");

-- AddForeignKey
ALTER TABLE "VpnServer" ADD CONSTRAINT "VpnServer_countryId_fkey" FOREIGN KEY ("countryId") REFERENCES "Country"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VpnServer" ADD CONSTRAINT "VpnServer_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "VpnProvider"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VpnConnection" ADD CONSTRAINT "VpnConnection_serverId_fkey" FOREIGN KEY ("serverId") REFERENCES "VpnServer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
