package cn.hieu.course_table

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "cn.hieu.course_table/island"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // hasFocusPermission() is a blocking IPC into SystemUI, so keep
                    // it off the platform thread.
                    "capability" -> {
                        val context = applicationContext
                        Thread {
                            val capability = FocusIsland.capability(context)
                            runOnUiThread { result.success(capability) }
                        }.start()
                    }
                    "openNotificationSettings" -> result.success(openNotificationSettings())
                    "openAutostartSettings" -> result.success(openAutostartSettings())
                    "startIsland" -> {
                        val intent = Intent(this, IslandService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "stopIsland" -> {
                        stopService(Intent(this, IslandService::class.java))
                        result.success(null)
                    }
                    "refreshIsland" -> {
                        startService(
                            Intent(this, IslandService::class.java)
                                .setAction(IslandService.ACTION_REFRESH),
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * The HyperOS focus-notification switch lives in the app notification page.
     * Returns false when no activity on this device can handle it.
     */
    private fun openNotificationSettings(): Boolean {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent("android.settings.APP_NOTIFICATION_SETTINGS")
                .putExtra("app_package", packageName)
                .putExtra("app_uid", applicationInfo.uid)
        }
        return startSafely(intent)
    }

    /**
     * Opens MIUI's autostart page, falling back to the app details page on ROMs
     * without it (HyperOS, AOSP, ...). resolveActivity() is not a reliable probe
     * here — it can report a match for MIUI components that are not installed —
     * so just attempt the start and fall through on failure.
     */
    private fun openAutostartSettings(): Boolean =
        startSafely(
            Intent().setComponent(
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                ),
            ),
        ) || startSafely(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            ),
        )

    private fun startSafely(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (error: Exception) {
        Log.w(TAG, "cannot start $intent", error)
        false
    }

    private companion object {
        const val TAG = "MainActivity"
    }
}
