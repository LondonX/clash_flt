package com.LondonX.clash_flt.service

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.content.getSystemService
import com.LondonX.clash_flt.R
import com.LondonX.clash_flt.util.parseCIDR
import com.github.kr328.clash.common.compat.pendingIntentFlags
import com.github.kr328.clash.common.constants.Components
import com.github.kr328.clash.core.Clash
import com.github.kr328.clash.core.model.Proxy
import com.github.kr328.clash.core.util.parseInetSocketAddress
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import java.net.InetSocketAddress
import kotlin.coroutines.resume
import kotlin.random.Random

class ClashVpnService : VpnService() {
    companion object {
        private var instance: ClashVpnService? = null
        private var isStarting = false
        private val continuations = arrayListOf<CancellableContinuation<ClashVpnService>>()

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

    override fun onCreate() {
        super.onCreate()
        instance = this
        continuations.forEach {
            if (it.isActive) it.resume(this)
        }
        continuations.clear()
    }

    /**
     * set enabled clash proxy node
     * @see Clash.patchSelector
     */
    fun patchSelector(groupName: String, proxy: Proxy): Boolean {
        return Clash.patchSelector(groupName, proxy.name)
    }

    private var isProxying = false

    /**
     * start Clash VPN
     * @see Clash.startTun
     * @see Clash.startHttp
     */
    fun startClash() {
        if (isProxying) return
        val vpnFd = setupVpn()
        Clash.startTun(
            fd = vpnFd.fd,
            gateway = "$TUN_GATEWAY/$TUN_SUBNET_PREFIX",
            portal = TUN_PORTAL,
            dns = NET_ANY,// dnsHijacking TUN_DNS
            markSocket = ::protect,
            querySocketUid = this::queryUid
        )
        isProxying = true
    }

    /**
     * stop Clash VPN
     * @see Clash.stopTun
     * @see Clash.stopHttp
     */
    fun stopClash() {
        Clash.stopTun()
        Clash.stopHttp()
        isProxying = false
    }

    private fun setupVpn(): ParcelFileDescriptor {
        Log.i(TAG, "setupVpn: start")
        val builder = Builder()
            .addAddress(TUN_GATEWAY, TUN_SUBNET_PREFIX)
            .setBlocking(false)
            .setMtu(TUN_MTU)
            .setSession("Clash")
            .addDnsServer(TUN_DNS)
            .setConfigureIntent(
                PendingIntent.getActivity(
                    this,
                    0,
                    Intent().setComponent(Components.MAIN_ACTIVITY),
                    pendingIntentFlags(PendingIntent.FLAG_UPDATE_CURRENT)
                )
            )
            .allowBypass()
            .apply {
                // bypassPrivateNetwork
                resources.getStringArray(R.array.bypass_private_route).map(::parseCIDR).forEach {
                    addRoute(it.ip, it.prefix)
                }
                addRoute(TUN_PORTAL, 32)
                // Metered
                if (Build.VERSION.SDK_INT >= 29) {
                    setMetered(false)
                }
                // System Proxy
                if (Build.VERSION.SDK_INT >= 29) {
                    listenHttp()?.let {
                        setHttpProxy(
                            ProxyInfo.buildDirectProxy(
                                it.address.hostAddress,
                                it.port,
                                HTTP_PROXY_LOCAL_LIST,
                            )
                        )
                    }
                }
            }
        val fd = builder.establish()
        Log.i(TAG, "setupVpn: end, fd != null: ${fd != null}")
        return fd!!
    }

    private fun queryUid(
        protocol: Int,
        source: InetSocketAddress,
        target: InetSocketAddress,
    ): Int {
        if (Build.VERSION.SDK_INT < 29)
            return -1
        val connectivity = this.getSystemService<ConnectivityManager>()!!
        return runCatching { connectivity.getConnectionOwnerUid(protocol, source, target) }
            .getOrElse { -1 }
    }
}

fun listenHttp(): InetSocketAddress? {
    val r = { 1 + Random.nextInt(199) }
    val listenAt = "127.${r()}.${r()}.${r()}:0"
    val address = Clash.startHttp(listenAt)

    return address?.let(::parseInetSocketAddress)
}

private const val TAG = "ClashVpnService"

private const val TUN_MTU = 0xFFFF
private const val TUN_SUBNET_PREFIX = 30
private const val TUN_GATEWAY = "172.19.0.1"
private const val TUN_PORTAL = "172.19.0.2"
private const val TUN_DNS = TUN_PORTAL
private const val NET_ANY = "0.0.0.0"
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