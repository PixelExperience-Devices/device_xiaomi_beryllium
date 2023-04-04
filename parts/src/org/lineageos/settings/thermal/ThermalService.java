/*
 * Copyright (C) 2020 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.lineageos.settings.thermal;

import android.app.ActivityManager;
import android.app.ActivityManager.StackInfo;
import android.app.IActivityManager;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;

public class ThermalService extends Service {

    private static final String TAG = "ThermalService";
    private static final boolean DEBUG = false;

    private final Handler mHandler = new Handler();

    private String mPreviousApp;
    private ThermalUtils mThermalUtils;
    private ActivityRunnable mActivityRunnable;
    private IActivityManager mIActivityManager;

    private BroadcastReceiver mIntentReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            if (Intent.ACTION_SCREEN_ON.equals(action)) {
                mHandler.postDelayed(mActivityRunnable, 500);
            } else {
                mHandler.removeCallbacks(mActivityRunnable);
                mPreviousApp = "";
                mThermalUtils.setDefaultThermalProfile();
            }
        }
    };

    @Override
    public void onCreate() {
        if (DEBUG) Log.d(TAG, "Creating service");
        mThermalUtils = new ThermalUtils(this);
        mActivityRunnable = new ActivityRunnable(this);
        mIActivityManager = ActivityManager.getService();
        mHandler.postDelayed(mActivityRunnable, 500);
        registerReceiver();
        super.onCreate();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (DEBUG) Log.d(TAG, "Starting service");
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void registerReceiver() {
        IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_SCREEN_ON);
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        this.registerReceiver(mIntentReceiver, filter);
    }

    private class ActivityRunnable implements Runnable {
        private Context context;

        private ActivityRunnable(Context context) {
            this.context = context;
        }

        @Override
        public void run() {
            try {
                StackInfo focusedStack = mIActivityManager.getFocusedStackInfo();
                if (focusedStack != null && focusedStack.topActivity != null) {
                    String foregroundApp = focusedStack.topActivity.getPackageName();
                    mHandler.postDelayed(this, 500);
                    if (!foregroundApp.equals(mPreviousApp)) {
                        mThermalUtils.setThermalProfile(foregroundApp);
                        mPreviousApp = foregroundApp;
                    }
                }
            } catch (RemoteException ignored) {
            }
        }
    }
}
