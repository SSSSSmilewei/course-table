"""Injects the HyperOS island Kotlin sources and manifest entries into the
generated android/ project. Idempotent: safe to re-run after `flutter create`
regenerates the project."""

import shutil
from pathlib import Path

root = Path("android")
kotlin_src = Path("tool/android_island/cn/hieu/course_table")
kotlin_dst = root / "app/src/main/kotlin/cn/hieu/course_table"

for source in kotlin_src.glob("*.kt"):
    shutil.copy(source, kotlin_dst / source.name)

manifest = root / "app/src/main/AndroidManifest.xml"
text = manifest.read_text(encoding="utf-8")

if "FOREGROUND_SERVICE_SPECIAL_USE" not in text:
    text = text.replace(
        "<application",
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
        '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\n'
        '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>\n'
        "    <application",
        1,
    )

if "IslandService" not in text:
    text = text.replace(
        "</application>",
        """<service
            android:name=".IslandService"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Keeps the HyperOS focus notification / super island in sync with the timetable"/>
        </service>
        <receiver android:name=".IslandBootReceiver" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>""",
        1,
    )

manifest.write_text(text, encoding="utf-8")
print("android island configured")
