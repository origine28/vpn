package com.vpnproj.vpnapp.vpn

import android.app.Service
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Service VPN Android (VpnService).
 *
 * Phase 2 : TUN legacy (adresse + DNS) pour afficher l'indicateur VPN.
 *
 * Phase 4 : Tunnel WireGuard réel via GoBackend.
 * - GoBackend configure le TUN, wireguard-go, et le handshake Curve25519
 * - CONNECTED est déclaré uniquement après handshake confirmé par GoBackend
 * - La clé privée client est générée via com.wireguard.crypto.KeyPair
 *   (Curve25519 officielle, pas SHA-256)
 */
class MainVpnService : VpnService() {
    private var tunFd: ParcelFileDescriptor? = null
    private var tunnelManager: WireGuardTunnelManager? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val isStopping = AtomicBoolean(false)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            executor.execute { establishTunnel(intent) }
        }
        return START_STICKY
    }

    private fun establishTunnel(intent: Intent) {
        val countryCode = intent.getStringExtra(EXTRA_COUNTRY_CODE) ?: "?"
        val serverName = intent.getStringExtra(EXTRA_SERVER_NAME) ?: "Serveur"

        val serverPublicKey = intent.getStringExtra(EXTRA_SERVER_PUBLIC_KEY)
        val serverEndpoint = intent.getStringExtra(EXTRA_SERVER_ENDPOINT)

        if (serverPublicKey != null && serverEndpoint != null) {
            establishWireGuardTunnel(
                countryCode = countryCode,
                serverName = serverName,
                serverPublicKey = serverPublicKey,
                serverEndpoint = serverEndpoint,
                presharedKey = intent.getStringExtra(EXTRA_PRESHARED_KEY),
                dnsServer = intent.getStringExtra(EXTRA_DNS_SERVER),
                allowedIPs = intent.getStringArrayExtra(EXTRA_ALLOWED_IPS)?.toList(),
            )
        } else {
            establishLegacyTunnel(countryCode, serverName)
        }
    }

    private fun establishWireGuardTunnel(
        countryCode: String,
        serverName: String,
        serverPublicKey: String,
        serverEndpoint: String,
        presharedKey: String?,
        dnsServer: String?,
        allowedIPs: List<String>?,
    ) {
        val (clientPrivateKey, clientPublicKey) = WireGuardKeyGenerator.generateKeyPair()

        Log.i(TAG, "Clé client générée (publique): ${clientPublicKey.take(8)}...")

        val wgConfig = WireGuardTunnelConfig(
            clientPrivateKey = clientPrivateKey,
            clientPublicKey = clientPublicKey,
            clientAddress = "10.8.0.2/32",
            serverPublicKey = serverPublicKey,
            serverEndpoint = serverEndpoint,
            presharedKey = presharedKey,
            allowedIPs = allowedIPs ?: listOf("0.0.0.0/0"),
            dnsServer = dnsServer ?: "1.1.1.1",
            mtu = 1420,
        )

        val manager = WireGuardTunnelManager(this)
        tunnelManager = manager

        val tunnelName = manager.startTunnel(wgConfig)

        if (tunnelName == null || !manager.isTunnelActive()) {
            Log.e(TAG, "Échec du tunnel WireGuard")
            VpnRuntime.instance?.onVpnError("Échec du démarrage du tunnel WireGuard")
            stopSelf()
            return
        }

        Log.i(TAG, "Tunnel WireGuard actif (handshake OK)")
        VpnRuntime.instance?.onVpnServiceReady()
    }

    private fun establishLegacyTunnel(countryCode: String, serverName: String) {
        val builder = Builder()
            .setSession("VPN Projet — $countryCode ($serverName)")
            .setMtu(1400)
            .addAddress("10.8.0.2", 32)
            .addDnsServer("8.8.8.8")

        val fd = try {
            builder.establish()
        } catch (exception: Exception) {
            VpnRuntime.instance?.onVpnError("Échec de l'établissement du TUN : ${exception.message}")
            stopSelf()
            return
        }

        if (fd == null) {
            VpnRuntime.instance?.onVpnError("TUN refusé par le système (autorisation requise)")
            stopSelf()
            return
        }

        tunFd = fd
        VpnRuntime.instance?.onVpnServiceReady()
    }

    override fun onDestroy() {
        isStopping.set(true)
        executor.execute {
            tunnelManager?.stopTunnel()
            tunnelManager = null
            tunFd?.close()
            tunFd = null
            VpnRuntime.instance?.onVpnServiceStopped()
        }
        super.onDestroy()
    }

    companion object {
        private const val TAG = "MainVpnService"
        const val EXTRA_COUNTRY_CODE = "country_code"
        const val EXTRA_SERVER_NAME = "server_name"
        const val EXTRA_SERVER_PORT = "server_port"

        const val EXTRA_SERVER_PUBLIC_KEY = "server_public_key"
        const val EXTRA_SERVER_ENDPOINT = "server_endpoint"
        const val EXTRA_PRESHARED_KEY = "preshared_key"
        const val EXTRA_DNS_SERVER = "dns_server"
        const val EXTRA_ALLOWED_IPS = "allowed_ips"
    }
}
