package com.vpnproj.vpnapp.vpn

/** Implémentation Pigeon : reçoit les appels de Flutter et délègue au [VpnRuntime]. */
class VpnMessenger(private val runtime: VpnRuntime) : VpnHostApi {
    override fun connect(config: VpnConnectConfig): VpnConnectResult =
        runtime.requestConnect(config)

    override fun disconnect() {
        runtime.requestDisconnect()
    }

    /**
     * Génère une paire de clés WireGuard côté appareil et retourne
     * la configuration tunnel complète. La clé privée reste locale.
     */
    override fun generateWireGuardConfig(config: VpnConnectConfig): WireGuardTunnelConfig {
        val (privateKey, publicKey) = WireGuardKeyGenerator.generateKeyPair()

        return WireGuardTunnelConfig(
            clientPrivateKey = privateKey,
            clientPublicKey = publicKey,
            clientAddress = "10.8.0.2/32",
            serverPublicKey = config.serverPublicKey ?: "",
            serverEndpoint = config.serverEndpoint ?: "",
            presharedKey = config.presharedKey,
            allowedIPs = config.allowedIPs ?: listOf("0.0.0.0/0", "::/0"),
            dnsServer = config.dnsServer ?: "1.1.1.1",
            mtu = 1420,
        )
    }
}
