package com.LondonX.clash_flt.service

import android.app.Activity
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import clash.Clash
import clash.Client
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONObject
import java.io.File
import kotlin.coroutines.resume

class ClashVpnService : VpnService() {
    companion object {
        private var instance: ClashVpnService? = null
        private var isStarting = false
        private val continuations = arrayListOf<CancellableContinuation<ClashVpnService>>()

        fun nullableInstance(): ClashVpnService? = instance

        suspend fun getInstance(context: Context): ClashVpnService {
            if (instance != null) return instance!!
            if (!isStarting) {
                isStarting = true
                context.startService(Intent(context, ClashVpnService::class.java))
            }
            return suspendCancellableCoroutine {
                continuations.add(it)
            }
        }
    }

    var trafficNowUp = 0L
        private set
    var trafficNowDown = 0L
        private set
    var trafficTotalUp = 0L
        private set
    var trafficTotalDown = 0L
        private set

    private val client = object : Client {
        override fun log(level: String?, message: String?) {
            Log.i(TAG, "[$level]$message")
        }

        override fun traffic(up: Long, down: Long) {
            trafficNowUp = up
            trafficNowDown = down
            trafficTotalUp += up
            trafficTotalDown += down
        }
    }
    private var vpnFd: ParcelFileDescriptor? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        continuations.forEach {
            if (it.isActive) it.resume(this)
        }
        continuations.clear()
    }

    fun notifyConfigChanged(): Boolean {
        val sp = getSharedPreferences("clash_fit.xml", Activity.MODE_PRIVATE)
        val clashHome = sp.getString("clashHome", null) ?: return false
        val profilePath = sp.getString("profilePath", null) ?: return false
        // val countryDBPath = sp.getString("countryDBPath", null) ?: return false
        val groupName = sp.getString("groupName", null) ?: return false
        val proxyName = sp.getString("proxyName", null) ?: return false

        val config = File(profilePath).readText()
        Clash.setup(clashHome, config, client)

        val data = JSONObject(mapOf(groupName to proxyName)).toString().toByteArray()
        Clash.patchSelector(data)
        return true
    }

    var isRunning = false
        private set

    fun startClash() {
        if (isRunning) return
        if (!notifyConfigChanged()) return
        vpnFd = setupVpn()
        isRunning = true
    }

    fun stopClash() {
        vpnFd?.close()
        isRunning = false
    }

    private fun setupVpn(): ParcelFileDescriptor {
        val builder = Builder()
            .addAddress(TUN_GATEWAY, TUN_SUBNET_PREFIX)
            .setBlocking(false)
            .setMtu(TUN_MTU)
            .setSession("Clash")
            .setConfigureIntent(
                PendingIntent.getActivity(
                    this,
                    0,
                    Intent().setComponent(ComponentName(packageName, "$packageName.MainActivity")),
                    pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT)
                )
            )
            .allowBypass()
            .apply {
                // Metered
                if (Build.VERSION.SDK_INT >= 29) {
                    setMetered(false)
                }
                // System Proxy
                if (Build.VERSION.SDK_INT >= 29) {
                    val general = JSONObject(String(Clash.getConfigGeneral()))
                    val port = general.getInt("port")
                    setHttpProxy(
                        ProxyInfo.buildDirectProxy(
                            "127.0.0.1",
                            port,
                            HTTP_PROXY_LOCAL_LIST,
                        )
                    )
                }
            }
        val fd = builder.establish()
        Log.i(TAG, "setupVpn: end, fd != null: ${fd != null}")
        return fd!!
    }
}

private const val TAG = "ClashVpnService"

private const val TUN_MTU = 0xFFFF
private const val TUN_SUBNET_PREFIX = 30
private const val TUN_GATEWAY = "172.19.0.1"

private val HTTP_PROXY_LOCAL_LIST = listOf(
    "localhost",
    "*.local",
    "127.*",
    "10.*",
    "172.16.*",
    "172.17.*",
    "172.18.*",
    "172.19.*",
    "172.2*",
    "172.30.*",
    "172.31.*",
    "192.168.*"
)

private fun pendingIntentFlags(flags: Int, mutable: Boolean = false): Int {
    return if (Build.VERSION.SDK_INT >= 24) {
        if (Build.VERSION.SDK_INT > 30 && mutable) {
            flags or PendingIntent.FLAG_MUTABLE
        } else {
            flags or PendingIntent.FLAG_IMMUTABLE
        }
    } else {
        flags
    }
}