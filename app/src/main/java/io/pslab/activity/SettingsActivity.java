package io.pslab.activity;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.view.MenuItem;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.Unbinder;
import io.pslab.R;
import io.pslab.fragment.AccelerometerSettingsFragment;
import io.pslab.fragment.BaroMeterSettingsFragment;
import io.pslab.fragment.CompassSettingsFragment;
import io.pslab.fragment.DustSensorSettingsFragment;
import io.pslab.fragment.GyroscopeSettingsFragment;
import io.pslab.fragment.LuxMeterSettingFragment;
import io.pslab.fragment.MultimeterSettingsFragment;
import io.pslab.fragment.SettingsFragment;
import io.pslab.fragment.SoundmeterSettingsFragment;
import io.pslab.fragment.ThermometerSettingsFragment;
import io.pslab.models.PSLabSensor;
import io.pslab.others.GPSLogger;


public class SettingsActivity extends AppCompatActivity {

    @BindView(R.id.setting_toolbar)
    Toolbar toolbar;
    @BindView(R.id.content)
    FrameLayout content;
    private Unbinder unBinder;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);
        unBinder = ButterKnife.bind(this);

        Intent intent = getIntent();
        String title = intent.getStringExtra("title");

        setSupportActionBar(toolbar);
        final ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setHomeAsUpIndicator(R.drawable.ic_arrow_back_white_24dp);
            actionBar.setDisplayHomeAsUpEnabled(true);
            actionBar.setTitle(title);
        }

        Button myButton = findViewById(R.id.myButton);
    myButton.setOnClickListener(new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            Toast.makeText(CompassActivity.this, "Button clicked!", Toast.LENGTH_SHORT).show();
        }
    });

        Fragment fragment;
        switch (title) {
            case PSLabSensor.LUXMETER_CONFIGURATIONS:
                fragment = new LuxMeterSettingFragment();
                break;
            case PSLabSensor.BAROMETER_CONFIGURATIONS:
                fragment = new BaroMeterSettingsFragment();
                break;
            case PSLabSensor.GYROSCOPE_CONFIGURATIONS:
                fragment = new GyroscopeSettingsFragment();
                break;
            case PSLabSensor.ACCELEROMETER_CONFIGURATIONS:
                fragment = new AccelerometerSettingsFragment();
                break;
            case PSLabSensor.THERMOMETER_CONFIGURATIONS:
                fragment = new ThermometerSettingsFragment();
                break;
            case "Multimeter Configurations":
                fragment = new MultimeterSettingsFragment();
                break;
            case PSLabSensor.COMPASS_CONFIGURATIONS:
                fragment = new CompassSettingsFragment();
                break;
            case PSLabSensor.DUSTSENSOR_CONFIGURATIONS:
                fragment = new DustSensorSettingsFragment();
                break;
            case PSLabSensor.SOUNDMETER_CONFIGURATIONS:
                fragment = new SoundmeterSettingsFragment();
                break;
            default:
                fragment = new SettingsFragment();
                break;
        }

        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction().add(R.id.content, fragment).commit();
        }
    }
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.activity_compass_help_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();

    if (id == android.R.id.home) {
        finish();
        return true;
    } else if (id == R.id.compass_record_data) {
      
        Toast.makeText(this, "Recording current compass data...", Toast.LENGTH_SHORT).show();
        return true;
    } else if (id == R.id.compass_help_icon) {
       
        Toast.makeText(this, "Opening compass help...", Toast.LENGTH_SHORT).show();
        return true;
    }
        
        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unBinder.unbind();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == GPSLogger.PSLAB_PERMISSION_FOR_MAPS && (grantResults.length <= 0
                || grantResults[0] != PackageManager.PERMISSION_GRANTED)) {
            SharedPreferences.Editor editor = PreferenceManager.getDefaultSharedPreferences(getBaseContext()).edit();
            editor.putBoolean(LuxMeterSettingFragment.KEY_INCLUDE_LOCATION, false);
            editor.apply();
        }
    }
}
