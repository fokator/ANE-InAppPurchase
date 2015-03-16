Air Native Extension for In-app purchases on iOS and Android (ARM and x86)
==================================

- Android In-app Billing Version 3 API. 
- Add this to you android manifest :

```xml
<android>
	<manifestAdditions><![CDATA[
		<manifest android:installLocation="auto">

			...

			<!-- IN APP PURCHASE -->
			<uses-permission android:name="com.android.vending.BILLING" />

			...

			<application>

				...

				<!-- IN APP PURCHASE -->
				<activity android:name="com.studiopixmix.anes.inapppurchase.activities.BillingActivity" android:theme="@android:style/Theme.Translucent.NoTitleBar.Fullscreen" />

			</application>

		</manifest>
	]]></manifestAdditions>
</android>
```
