package com.LondonX.clash_flt

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import androidx.annotation.NonNull
import com.LondonX.clash_flt.service.ClashVpnService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import kotlin.coroutines.resume

private const val ACTION_PREPARE_VPN = 0xF1

class ClashFltPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private val scope = MainScope()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "clash_flt")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "queryTrafficNow" -> {
                nullableClashServiceScope(result) {
                    result.success(
                        mapOf(
                            "up" to (it?.trafficNowUp ?: 0L),
                            "down" to (it?.trafficNowDown ?: 0L),
                        )
                    )
                }
            }
            "queryTrafficTotal" -> {
                nullableClashServiceScope(result) {
                    result.success(
                        mapOf(
                            "up" to (it?.trafficTotalUp ?: 0L),
                            "down" to (it?.trafficTotalDown ?: 0L),
                        )
                    )
                }
            }
            "applyConfig" -> {
                val clashHome = call.argument<String>("clashHome")
                val profilePath = call.argument<String>("profilePath")
                val countryDBPath = call.argument<String>("countryDBPath")
                val groupName = call.argument<String>("groupName")
                val proxyName = call.argument<String>("proxyName")
                activity?.getSharedPreferences("clash_fit.xml", Activity.MODE_PRIVATE)?.edit()
                    ?.apply {
                        putString("clashHome", clashHome)
                        putString("profilePath", profilePath)
                        putString("countryDBPath", countryDBPath)
                        putString("groupName", groupName)
                        putString("proxyName", proxyName)
                        apply()
                    }
                result.success(true)
                nullableClashServiceScope(result) {
                    if (it?.isRunning == true) {
                        it.notifyConfigChanged()
                    }
                }
            }
            "isClashRunning" -> {
                nullableClashServiceScope(result) {
                    result.success(it?.isRunning == true)
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
            "setIncludeApps" -> {
                val packages = call.argument<List<String>>("packages")
                if (packages == null) {
                    result.success(false)
                    return
                }
                activity?.getSharedPreferences("clash_fit.xml", Activity.MODE_PRIVATE)?.edit()
                    ?.apply {
                        putStringSet("includeAppPackages", packages.toSet())
                        apply()
                    }
                nullableClashServiceScope(result) {
                    if (it?.isRunning == true) {
                        it.notifyConfigChanged()
                    }
                }
                result.success(false)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        scope.cancel()
        channel.setMethodCallHandler(null)
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

    private fun nullableClashServiceScope(
        result: Result,
        withService: suspend CoroutineScope.(ClashVpnService?) -> Unit,
    ) {
        val activity = this.activity
        if (activity == null) {
            result.error("Clash.startClash", "activity is null!!!", null)
            return
        }
        scope.launch {
            val service = ClashVpnService.nullableInstance()
            withService.invoke(this, service)
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
