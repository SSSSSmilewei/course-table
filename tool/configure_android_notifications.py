from pathlib import Path


root = Path("android")
manifest = root / "app/src/main/AndroidManifest.xml"
text = manifest.read_text(encoding="utf-8")
text = text.replace(
    "<manifest xmlns:android=",
    '<manifest xmlns:android=',
    1,
)
text = text.replace(
    "<application",
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n'
    # 连接协会平台（导入课程、同步学习记录）要联网；正式版默认没有这个权限
    '    <uses-permission android:name="android.permission.INTERNET"/>\n'
    '    <application',
    1,
)
text = text.replace(
    "</application>",
    '''<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>''',
    1,
)
manifest.write_text(text, encoding="utf-8")

gradle = root / "app/build.gradle.kts"
text = gradle.read_text(encoding="utf-8")
text = text.replace(
    "compileOptions {\n",
    "compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n",
    1,
)
text = text.replace(
    "defaultConfig {\n",
    "defaultConfig {\n        multiDexEnabled = true\n",
    1,
)
text += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
gradle.write_text(text, encoding="utf-8")
