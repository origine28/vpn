package com.vpnproj.vpnapp.vpn

/**
 * Machine à états VPN côté Android, en Kotlin pur (aucune dépendance Android)
 * pour rester unit-testable sur JVM.
 *
 * Transitions : DISCONNECTED → CONNECTING → CONNECTED → DISCONNECTING → DISCONNECTED,
 * plus passage par ERROR en cas d'échec. Chaque transition émet un
 * [VpnStatusEvent] via [listener].
 */
class VpnEngine(
    private val listener: (VpnStatusEvent) -> Unit,
) {
    var status: VpnAndroidState = VpnAndroidState.DISCONNECTED
        private set

    var lastConfig: VpnConnectConfig? = null
        private set

    fun connect(config: VpnConnectConfig) {
        if (status != VpnAndroidState.DISCONNECTED && status != VpnAndroidState.ERROR) {
            return
        }
        lastConfig = config
        emit(VpnAndroidState.CONNECTING, "Connexion à ${config.serverName}…")
    }

    fun onTunnelEstablished() {
        if (status != VpnAndroidState.CONNECTING) {
            return
        }
        emit(VpnAndroidState.CONNECTED, "Tunnel VPN établi")
    }

    fun onError(message: String) {
        if (status == VpnAndroidState.DISCONNECTED) {
            return
        }
        emit(VpnAndroidState.ERROR, message)
        status = VpnAndroidState.DISCONNECTED
    }

    fun disconnect() {
        when (status) {
            VpnAndroidState.CONNECTED ->
                emit(VpnAndroidState.DISCONNECTING, "Déconnexion en cours…")

            VpnAndroidState.CONNECTING ->
                emit(VpnAndroidState.DISCONNECTED, "Connexion annulée")

            else -> Unit
        }
    }

    fun onServiceStopped() {
        if (status != VpnAndroidState.DISCONNECTED && status != VpnAndroidState.ERROR) {
            emit(VpnAndroidState.DISCONNECTED, null)
        }
    }

    private fun emit(state: VpnAndroidState, message: String?) {
        status = state
        listener(VpnStatusEvent(state, message))
    }
}
