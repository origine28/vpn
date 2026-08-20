package com.vpnproj.vpnapp.vpn

import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.plugin.common.BinaryMessenger

/**
 * Coordinateur entre Flutter (via Pigeon), le [VpnEngine] et le [MainVpnService].
 *
 * - [requestConnect] vérifie l'autorisation système [VpnService.prepare] ; si elle
 *   manque, déclenche le dialogue système via [launchPermission] et garde la
 *   configuration en attente ([onPermissionGranted]).
 * - L'état du [VpnEngine] est retransmis à Flutter par le canal d'événements
 *   ([StatusEventsStreamHandler]).
 * - En Phase 4, la configuration WireGuard est transmise au service via les extras
 *   de l'Intent.
 */
class VpnRuntime(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val launchPermission: () -> Unit,
) : StatusEventsStreamHandler() {

    private var sink: PigeonEventSink<VpnStatusEvent>? = null
    private var pendingConfig: VpnConnectConfig? = null

    val engine = VpnEngine(::onEngineEvent)

    fun attach() {
        VpnHostApi.setUp(messenger, VpnMessenger(this))
        StatusEventsStreamHandler.register(messenger, this)
    }

    fun detach() {
        VpnHostApi.setUp(messenger, null)
    }

    fun requestConnect(config: VpnConnectConfig): VpnConnectResult {
        if (VpnService.prepare(context) != null) {
            pendingConfig = config
            launchPermission()
            return VpnConnectResult(false, "VPN_NOT_PREPARED")
        }
        engine.connect(config)
        startVpnService(config)
        return VpnConnectResult(true, null)
    }

    fun requestDisconnect() {
        engine.disconnect()
        context.stopService(Intent(context, MainVpnService::class.java))
    }

    fun onPermissionGranted() {
        val config = pendingConfig ?: return
        pendingConfig = null
        engine.connect(config)
        startVpnService(config)
    }

    fun onPermissionDenied() {
        pendingConfig = null
        engine.onError("Autorisation VPN refusée")
    }

    fun onVpnServiceReady() {
        engine.onTunnelEstablished()
    }

    fun onVpnError(message: String) {
        engine.onError(message)
    }

    fun onVpnServiceStopped() {
        engine.onServiceStopped()
    }

    private fun startVpnService(config: VpnConnectConfig) {
        val intent = Intent(context, MainVpnService::class.java).apply {
            putExtra(MainVpnService.EXTRA_COUNTRY_CODE, config.countryCode)
            putExtra(MainVpnService.EXTRA_SERVER_NAME, config.serverName)
            config.serverPort?.let { putExtra(MainVpnService.EXTRA_SERVER_PORT, it) }

            // WireGuard configuration (Phase 4)
            config.serverPublicKey?.let { putExtra(MainVpnService.EXTRA_SERVER_PUBLIC_KEY, it) }
            config.serverEndpoint?.let { putExtra(MainVpnService.EXTRA_SERVER_ENDPOINT, it) }
            config.presharedKey?.let { putExtra(MainVpnService.EXTRA_PRESHARED_KEY, it) }
            config.dnsServer?.let { putExtra(MainVpnService.EXTRA_DNS_SERVER, it) }
            config.allowedIPs?.let { putExtra(MainVpnService.EXTRA_ALLOWED_IPS, it.toTypedArray()) }
        }
        context.startService(intent)
    }

    private fun onEngineEvent(event: VpnStatusEvent) {
        sink?.success(event)
    }

    override fun onListen(p0: Any?, sink: PigeonEventSink<VpnStatusEvent>) {
        this.sink = sink
        sink.success(VpnStatusEvent(engine.status, null))
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    companion object {
        @Volatile
        var instance: VpnRuntime? = null
    }
}
