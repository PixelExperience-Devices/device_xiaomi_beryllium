/*
 * Copyright (C) 2018,2020 The LineageOS Project
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

package org.lineageos.settings.dirac;

import android.os.Bundle;
import android.widget.Switch;

import androidx.preference.ListPreference;
import androidx.preference.Preference;
import androidx.preference.PreferenceCategory;
import androidx.preference.PreferenceFragment;
import androidx.preference.SwitchPreference;

import com.android.settingslib.widget.MainSwitchPreference;
import com.android.settingslib.widget.OnMainSwitchChangeListener;

import org.lineageos.settings.R;

public class DiracSettingsFragment extends PreferenceFragment implements
        Preference.OnPreferenceChangeListener, OnMainSwitchChangeListener {

    private static final String PREF_ENABLE = "dirac_enable";
    private static final String PREF_HEADSET = "dirac_headset_pref";
    private static final String PREF_PRESET = "dirac_preset_pref";

    private MainSwitchPreference mSwitchBar;

    private ListPreference mHeadsetType;
    private ListPreference mPreset;

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        addPreferencesFromResource(R.xml.dirac_settings);

        DiracUtils.initialize();
        boolean enhancerEnabled = DiracUtils.isDiracEnabled(getActivity());

        mSwitchBar = (MainSwitchPreference) findPreference(PREF_ENABLE);
        mSwitchBar.addOnSwitchChangeListener(this);
        mSwitchBar.setChecked(enhancerEnabled);

        mHeadsetType = (ListPreference) findPreference(PREF_HEADSET);
        mHeadsetType.setOnPreferenceChangeListener(this);
        mHeadsetType.setEnabled(enhancerEnabled);

        mPreset = (ListPreference) findPreference(PREF_PRESET);
        mPreset.setOnPreferenceChangeListener(this);
        mPreset.setEnabled(enhancerEnabled);
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        switch (preference.getKey()) {
            case PREF_HEADSET:
                DiracUtils.setHeadsetType(Integer.parseInt(newValue.toString()));
                return true;
            case PREF_PRESET:
                DiracUtils.setLevel(String.valueOf(newValue));
                return true;
            default:
                return false;
        }
    }

    @Override
    public void onSwitchChanged(Switch switchView, boolean isChecked) {
        mSwitchBar.setChecked(isChecked);

        DiracUtils.setMusic(isChecked);

        mHeadsetType.setEnabled(isChecked);
        mPreset.setEnabled(isChecked);
    }
}
