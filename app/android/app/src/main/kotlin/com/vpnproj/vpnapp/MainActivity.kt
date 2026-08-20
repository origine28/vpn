package com.vpnproj.vpnapp

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import com.vpnproj.vpnapp.vpn.VpnRuntime
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_PERMISSION_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                VpnRuntime.instance?.onPermissionGranted()
            } else {
                VpnRuntime.instance?.onPermissionDenied()
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val runtime = VpnRuntime(
            context = applicationContext,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
            launchPermission = {
                VpnService.prepare(this@MainActivity)
                    ?.let { startActivityForResult(it, VPN_PERMISSION_REQUEST) }
            },
        )
        VpnRuntime.instance = runtime
        runtime.attach()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        VpnRuntime.instance?.detach()
        VpnRuntime.instance = null
    }

    companion object {
        private const val VPN_PERMISSION_REQUEST = 7100
    }
}
