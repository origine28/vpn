package com.vpnproj.vpnapp.vpn

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class VpnEngineTest {

    private val config = VpnConnectConfig(countryCode = "FR", serverName = "France — Serveur")

    private fun engineOf(events: MutableList<VpnStatusEvent>): VpnEngine =
        VpnEngine { events.add(it) }

    @Test
    fun `état initial déconnecté`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        assertEquals(VpnAndroidState.DISCONNECTED, engine.status)
        assertNull(engine.lastConfig)
        assertTrue(events.isEmpty())
    }

    @Test
    fun `connect émet CONNECTING et mémorise la config`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        engine.connect(config)

        assertEquals(VpnAndroidState.CONNECTING, engine.status)
        assertEquals(config, engine.lastConfig)
        assertEquals(1, events.size)
        assertEquals(VpnAndroidState.CONNECTING, events[0].state)
    }

    @Test
    fun `cycle complet connecté puis déconnecté`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        engine.connect(config)
        engine.onTunnelEstablished()
        assertEquals(VpnAndroidState.CONNECTED, engine.status)

        engine.disconnect()
        assertEquals(VpnAndroidState.DISCONNECTING, engine.status)
        engine.onServiceStopped()
        assertEquals(VpnAndroidState.DISCONNECTED, engine.status)

        assertEquals(
            listOf(
                VpnAndroidState.CONNECTING,
                VpnAndroidState.CONNECTED,
                VpnAndroidState.DISCONNECTING,
                VpnAndroidState.DISCONNECTED,
            ),
            events.map { it.state },
        )
    }

    @Test
    fun `erreur émet ERROR puis retombe sur DISCONNECTED`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        engine.connect(config)
        engine.onError("Serveur indisponible")

        assertEquals(VpnAndroidState.DISCONNECTED, engine.status)
        assertEquals(2, events.size)
        assertEquals(VpnAndroidState.ERROR, events[1].state)
        assertEquals("Serveur indisponible", events[1].message)

        // Après une erreur, une nouvelle connexion est possible.
        engine.connect(config)
        assertEquals(VpnAndroidState.CONNECTING, engine.status)
    }

    @Test
    fun `déconnexion pendant CONNECTING annule la connexion`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        engine.connect(config)
        engine.disconnect()

        assertEquals(VpnAndroidState.DISCONNECTED, engine.status)
        assertEquals(
            listOf(VpnAndroidState.CONNECTING, VpnAndroidState.DISCONNECTED),
            events.map { it.state },
        )
    }

    @Test
    fun `onTunnelEstablished ignoré si on n'attend pas`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        engine.onTunnelEstablished()

        assertEquals(VpnAndroidState.DISCONNECTED, engine.status)
        assertTrue(events.isEmpty())
    }

    @Test
    fun `connect quand déjà connecté est ignoré`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        engine.connect(config)
        engine.onTunnelEstablished()
        val sizeBefore = events.size

        engine.connect(VpnConnectConfig("DE", "Allemagne — Serveur"))

        assertEquals(VpnAndroidState.CONNECTED, engine.status)
        assertEquals(sizeBefore, events.size)
        assertEquals(config, engine.lastConfig)
    }

    @Test
    fun `onServiceStopped seul ramène à DISCONNECTED`() {
        val events = mutableListOf<VpnStatusEvent>()
        val engine = engineOf(events)

        engine.connect(config)
        engine.onServiceStopped()

        assertEquals(VpnAndroidState.DISCONNECTED, engine.status)
        assertEquals(VpnAndroidState.DISCONNECTED, events.last().state)
    }
}
