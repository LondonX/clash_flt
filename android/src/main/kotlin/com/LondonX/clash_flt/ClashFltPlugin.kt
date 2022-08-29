package com.LondonX.clash_flt

import android.app.Activity
import android.app.Application
import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.LondonX.clash_flt.service.ClashVpnService
import com.LondonX.clash_flt.util.toMap
import com.LondonX.clash_flt.util.toProviderType
import com.LondonX.clash_flt.util.toProxySort
import com.LondonX.clash_flt.util.toProxyType
import com.github.kr328.clash.common.Global
import com.github.kr328.clash.core.Clash
import com.github.kr328.clash.core.model.Proxy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import java.io.File
import kotlin.coroutines.resume

private const val ACTION_PREPARE_VPN = 0xF1

class ClashFltPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private val uiHandler = Handler(Looper.getMainLooper())
    private val scope = MainScope()
    private val logSubs = hashMapOf<String, Job>()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Global.init(flutterPluginBinding.applicationContext as Application)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "clash_flt")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val callbackKey = call.argument<String>("callbackKey")
        when (call.method) {
            "reset" -> {
                Clash.reset()
                result.success(null)
            }
            "forceGc" -> {
                Clash.forceGc()
                result.success(null)
            }
            "suspendCore" -> {
                val suspended = call.argument<Boolean>("suspended")!!
                Clash.suspendCore(suspended)
                result.success(null)
            }
            "queryTunnelState" -> {
                val tunState = Clash.queryTunnelState()
                result.success(tunState.toMap())
            }
            "queryTrafficNow" -> {
//                val traffic: Long = Clash.queryTrafficNow()
//                result.success(traffic)
                result.notImplemented()
            }
            "queryTrafficTotal" -> {
//                val traffic: Long = Clash.queryTrafficTotal()
//                result.success(traffic)
                result.notImplemented()
            }
            "notifyDnsChanged" -> {
                val path = call.argument<List<String>>("dns")!!
                Clash.notifyDnsChanged(path)
                result.success(null)
            }
            "notifyTimeZoneChanged" -> {
                val name = call.argument<String>("name")!!
                val offset = call.argument<Int>("offset")!!
                Clash.notifyTimeZoneChanged(name, offset)
                result.success(null)
            }
            "notifyInstalledAppsChanged" -> {
                result.notImplemented()
            }
            "healthCheck" -> {
                val name = call.argument<String>("name")!!
                Clash.healthCheck(name)
                result.success(null)
            }
            "healthCheckAll" -> {
                Clash.healthCheckAll()
                result.success(null)
            }
            "queryOverride" -> {
                result.notImplemented()
            }
            "installSideloadGeoip" -> {
                val path = call.argument<String>("path")!!
                val data = File(path).readBytes()
                Clash.installSideloadGeoip(data)
                result.success(null)
            }
            "subscribeLogcat" -> {
                logSubs[callbackKey]?.cancel()
                logSubs[callbackKey!!] = scope.launch {
                    while (isActive) {
                        val message = Clash.subscribeLogcat().receive()
                        callbackWithKey(callbackKey, message.toMap())
                    }
                }
            }
            "unsubscribeLogcat" -> {
                logSubs[callbackKey]?.cancel()
                logSubs.remove(callbackKey)
            }
            "fetchAndValid" -> {
                val url = call.argument<String>("url")!!
                val force = call.argument<Boolean>("force")!!
                val profilesDir = File(activity!!.filesDir, "profiles")
                profilesDir.mkdirs()
                Clash.fetchAndValid(profilesDir, url, force) {
                    uiHandler.post {
                        callbackWithKey(callbackKey, it.toMap())
                    }
                }.result(result, "Clash.fetchAndValid")
            }
            "load" -> {
                val path = call.argument<String>("path")!!
                val file = File(path)
                Clash.load(file).result(result, "Clash.load")
            }
            "queryProviders" -> {
                val providers = Clash.queryProviders()
                result.success(providers.map { it.toMap() })
            }
            "updateProvider" -> {
                val name = call.argument<String>("name")!!
                val type = call.argument<String>("type")?.toProviderType() ?: return result.error(
                    "Clash.updateProvider",
                    "Supported type!!!",
                    null,
                )
                Clash.updateProvider(type, name)
            }
            "queryGroupNames" -> {
                val excludeNotSelectable = call.argument<Boolean>("excludeNotSelectable")!!
                val names = Clash.queryGroupNames(excludeNotSelectable)
                result.success(names)
            }
            "queryGroup" -> {
                val name = call.argument<String>("name")!!
                val proxySort = call.argument<String>("proxySort").toProxySort()
                val group = Clash.queryGroup(name, proxySort)
                result.success(group.toMap())
            }
            "patchSelector" -> {
                val groupName = call.argument<String>("groupName")
                val name = call.argument<String>("name")
                val title = call.argument<String>("title")
                val subtitle = call.argument<String>("subtitle")
                val type = call.argument<String>("type").toProxyType()
                val delay = call.argument<Int>("delay")
                val proxy =
                    if (name == null || title == null || subtitle == null || delay == null) {
                        null
                    } else {
                        Proxy(name, title, subtitle, type, delay)
                    }
                if (groupName == null || proxy == null) {
                    result.success(false)
                    return
                }
                clashServiceScope(result) {
                    val patched = it.patchSelector(groupName, proxy)
                    result.success(patched)
                }
            }
            "isClashRunning" -> {
                clashServiceScope(result) {
                    result.success(it.isRunning())
                }
            }
            "startClash" -> {
                clashServiceScope(result) {
                    val prepared = prepareClash()
                    if (!prepared) {
                        result.success(false)
                        return@clashServiceScope
                    }
                    it.startClash()
                    result.success(true)
                }
            }
            "stopClash" -> {
                clashServiceScope(result) {
                    it.stopClash()
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        scope.cancel()
        channel.setMethodCallHandler(null)
        Global.destroy()
    }

    private fun callbackWithKey(callbackKey: String?, params: Map<String, Any?>) {
        channel.invokeMethod(
            "callbackWithKey",
            mapOf(
                "callbackKey" to callbackKey,
                "params" to params,
            ),
        )
    }

    private var activity: Activity? = null
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.removeActivityResultListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == ACTION_PREPARE_VPN) {
            if (scope.isActive && vpnPreparing?.isActive == true) {
                vpnPreparing?.resume(resultCode == Activity.RESULT_OK)
            }
            return true
        }
        return false
    }

    private var vpnPreparing: CancellableContinuation<Boolean>? = null
    private suspend fun prepareClash(): Boolean {
        val activity = activity ?: return false
        val prepareIntent = VpnService.prepare(activity) ?: return true
        activity.startActivityForResult(prepareIntent, ACTION_PREPARE_VPN)
        return suspendCancellableCoroutine {
            vpnPreparing = it
        }
    }

    private fun clashServiceScope(
        result: Result,
        withService: suspend CoroutineScope.(ClashVpnService) -> Unit,
    ) {
        val activity = this.activity
        if (activity == null) {
            result.error("Clash.startClash", "activity is null!!!", null)
            return
        }
        scope.launch {
            val service = ClashVpnService.getInstance(activity)
            withService.invoke(this, service)
        }
    }
}

private fun CompletableDeferred<*>.result(result: Result, errorCode: String) {
    this.invokeOnCompletion {
        if (it == null) {
            result.success(null)
            return@invokeOnCompletion
        }
        result.error(errorCode, it.message, null)
        it.printStackTrace()
    }
}