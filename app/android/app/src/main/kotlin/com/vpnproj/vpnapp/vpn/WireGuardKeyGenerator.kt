package com.vpnproj.vpnapp.vpn

import com.wireguard.config.Config
import com.wireguard.crypto.Key
import com.wireguard.crypto.KeyPair
import java.io.StringReader

/**
 * Génération de clés Curve25519 officielles WireGuard.
 *
 * Utilise `com.wireguard.crypto.KeyPair` de la bibliothèque
 * `com.wireguard.android:tunnel` qui implémente Curve25519 en pur Java
 * (clamping conforme à la spec RFC 7748).
 *
 * La clé privée est générée via SecureRandom, clamped selon la spec,
 * et ne quitte jamais l'appareil.
 */
object WireGuardKeyGenerator {

    /**
     * Génère une paire de clés Curve25519 officielle WireGuard.
     * Retourne [privateKeyBase64, publicKeyBase64].
     *
     * La clé privée reste locale. Seule la clé publique
     * doit être envoyée au backend/provider.
     */
    fun generateKeyPair(): Pair<String, String> {
        val keyPair = KeyPair()
        val privateKey = keyPair.privateKey
        val publicKey = keyPair.publicKey
        return Pair(privateKey.toBase64(), publicKey.toBase64())
    }

    /**
     * Vérifie qu'une clé privée base64 est valide (Curve25519).
     */
    fun isValidPrivateKey(base64: String): Boolean {
        return try {
            val key = Key.fromBase64(base64)
            key != null
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Vérifie qu'une clé publique base64 est valide (Curve25519).
     */
    fun isValidPublicKey(base64: String): Boolean {
        return try {
            val key = Key.fromBase64(base64)
            key != null
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Dérive la clé publique à partir d'une clé privée.
     */
    fun derivePublicKey(privateKeyBase64: String): String {
        val privateKey = Key.fromBase64(privateKeyBase64)
        val publicKey = Key.generatePublicKey(privateKey)
        return publicKey.toBase64()
    }

    /**
     * Construit une configuration WireGuard complète en format texte.
     * La clé privée côté client est injectée uniquement ici, côté appareil.
     * Le backend ne retourne JAMAIS la clé privée.
     */
    fun buildWireGuardConfigString(
        clientPrivateKey: String,
        serverPublicKey: String,
        serverEndpoint: String,
        clientAddress: String = "10.8.0.2/32",
        presharedKey: String? = null,
        allowedIPs: List<String> = listOf("0.0.0.0/0"),
        dnsServer: String = "1.1.1.1",
        mtu: Int = 1420,
    ): String {
        val sb = StringBuilder()
        sb.appendLine("[Interface]")
        sb.appendLine("PrivateKey = $clientPrivateKey")
        sb.appendLine("Address = $clientAddress")
        sb.appendLine("DNS = $dnsServer")
        sb.appendLine("MTU = $mtu")
        sb.appendLine()
        sb.appendLine("[Peer]")
        sb.appendLine("PublicKey = $serverPublicKey")
        if (presharedKey != null) {
            sb.appendLine("PresharedKey = $presharedKey")
        }
        sb.appendLine("Endpoint = $serverEndpoint")
        sb.appendLine("AllowedIPs = ${allowedIPs.joinToString(", ")}")
        sb.appendLine("PersistentKeepalive = 25")
        return sb.toString()
    }

    /**
     * Parse une configuration WireGuard texte en objet `Config`
     * de la bibliothèque officielle.
     */
    fun parseConfig(configString: String): Config {
        return Config.parse(StringReader(configString))
    }
}
