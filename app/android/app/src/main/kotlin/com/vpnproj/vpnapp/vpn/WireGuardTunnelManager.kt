package com.vpnproj.vpnapp.vpn

import android.content.Context
import android.util.Log
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import com.wireguard.config.InetEndpoint
import com.wireguard.config.InetNetwork
import com.wireguard.config.Interface
import com.wireguard.config.Peer
import java.io.StringReader
import java.util.concurrent.atomic.AtomicReference

/**
 * Représente les états internes du tunnel WireGuard.
 * Ces états sont plus granulaires que VpnAndroidState (Pigeon).
 */
enum class WireGuardTunnelState {
    DOWN,
    STARTING,
    UP,
    TRANSFER_TX,
    TRANSFER_RX,
}

/**
 * Tunnel WireGuard basé sur `GoBackend` de la bibliothèque officielle.
 *
 * `GoBackend` utilise wireguard-go via JNI pour créer un vrai tunnel
 * WireGuard chiffré (UDP). Contrairement à la création manuelle d'un TUN,
 * GoBackend gère :
 * - La configuration du TUN via VpnService.Builder
 * - Le handshake Curve25519 avec le serveur
 * - Le chiffrement/déchiffrement UDP WireGuard
 * - Le keepalive
 * - Le routage
 */
class WireGuardTunnel(
    private val tunnelName: String,
) : Tunnel {

    @Volatile
    var currentState: WireGuardTunnelState = WireGuardTunnelState.DOWN
        private set

    override fun getName(): String = tunnelName

    override fun onStateChange(newState: Tunnel.State) {
        Log.d(TAG, "Tunnel state changed: $newState")
        currentState = when (newState) {
            Tunnel.State.UP -> WireGuardTunnelState.UP
            Tunnel.State.DOWN -> WireGuardTunnelState.DOWN
            Tunnel.State.TUNNEL_TRANSFER_TX -> WireGuardTunnelState.TRANSFER_TX
            Tunnel.State.TUNNEL_TRANSFER_RX -> WireGuardTunnelState.TRANSFER_RX
        }
    }

    fun isUp(): Boolean = currentState == WireGuardTunnelState.UP

    companion object {
        private const val TAG = "WireGuardTunnel"
    }
}

/**
 * Gestionnaire du tunnel WireGuard utilisant `GoBackend`.
 *
 * Architecture :
 * 1. Génère les clés Curve25519 client via `WireGuardKeyGenerator`
 * 2. Construit un objet `Config` WireGuard officiel
 * 3. Utilise `GoBackend.setState(tunnel, UP, config)` pour démarrer le tunnel
 * 4. GoBackend crée le TUN, configure wireguard-go, et lance le handshake
 * 5. Le tunnel UP confirme le handshake réussi
 *
 * IMPORTANT : `GoBackend.setState()` est bloquant (DNS resolution + tunnel setup).
 * Doit être appelé hors du thread principal.
 */
class WireGuardTunnelManager(
    private val context: Context,
) {
    private val tunnelState = AtomicReference<WireGuardTunnelState>(WireGuardTunnelState.DOWN)
    private var backend: GoBackend? = null
    private var tunnel: WireGuardTunnel? = null

    /**
     * Démarre le tunnel WireGuard avec la configuration donnée.
     * Doit être appelé sur un thread secondaire.
     *
     * @return le nom du tunnel si succès, null si échec
     */
    fun startTunnel(config: WireGuardTunnelConfig): String? {
        try {
            val wgConfig = buildWireGuardConfig(config)
            val tunnelName = "vpn-${config.serverEndpoint}"

            val wgTunnel = WireGuardTunnel(tunnelName)
            tunnel = wgTunnel

            val goBackend = GoBackend(context)
            backend = goBackend

            tunnelState.set(WireGuardTunnelState.STARTING)
            wgTunnel.currentState = WireGuardTunnelState.STARTING

            goBackend.setState(wgTunnel, Tunnel.State.UP, wgConfig)

            tunnelState.set(WireGuardTunnelState.UP)
            wgTunnel.currentState = WireGuardTunnelState.UP

            Log.i(TAG, "Tunnel WireGuard démarré: $tunnelName")
            return tunnelName
        } catch (e: Exception) {
            Log.e(TAG, "Échec du démarrage du tunnel WireGuard", e)
            tunnelState.set(WireGuardTunnelState.DOWN)
            cleanup()
            return null
        }
    }

    /**
     * Arrête le tunnel WireGuard et libère les ressources.
     * Doit être appelé sur un thread secondaire.
     */
    fun stopTunnel() {
        try {
            val wgTunnel = tunnel
            val goBackend = backend

            if (wgTunnel != null && goBackend != null) {
                goBackend.setState(wgTunnel, Tunnel.State.DOWN, null)
            }

            tunnelState.set(WireGuardTunnelState.DOWN)
            cleanup()
            Log.i(TAG, "Tunnel WireGuard arrêté")
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de l'arrêt du tunnel", e)
            cleanup()
        }
    }

    /**
     * Vérifie si le tunnel est actif (handshake réussi).
     */
    fun isTunnelActive(): Boolean {
        return tunnel?.isUp() == true
    }

    /**
     * Retourne l'état actuel du tunnel.
     */
    fun getState(): WireGuardTunnelState = tunnelState.get()

    private fun cleanup() {
        tunnel = null
        backend = null
        tunnelState.set(WireGuardTunnelState.DOWN)
    }

    private fun buildWireGuardConfig(config: WireGuardTunnelConfig): Config {
        val clientAddress = config.clientAddress.split("/")
        val address = clientAddress[0]
        val prefix = clientAddress.getOrNull(1)?.toIntOrNull() ?: 32

        val interfaceBuilder = Interface.Builder()
            .parsePrivateKey(config.clientPrivateKey)
            .addAddress(InetNetwork.parse("$address/$prefix"))
            .setMtu(config.mtu?.toInt() ?: 1420)

        val dns = config.dnsServer
        if (dns != null) {
            interfaceBuilder.addDnsServer(InetNetwork.parse("$dns/32"))
        }

        val peerBuilder = Peer.Builder()
            .parsePublicKey(config.serverPublicKey)
            .setEndpoint(InetEndpoint.parse(config.serverEndpoint))
            .parsePresharedKey(config.presharedKey)
            .parseAllowedIPs(config.allowedIPs?.joinToString("\n") ?: "0.0.0.0/0")

        return Config.Builder()
            .setInterface(interfaceBuilder.build())
            .addPeer(peerBuilder.build())
            .build()
    }

    companion object {
        private const val TAG = "WireGuardTunnelMgr"
    }
}
