package io.pslab.activity;

import static io.pslab.others.ScienceLabCommon.scienceLab;

import android.app.PendingIntent;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.browser.customtabs.CustomTabsServiceConnection;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;

import com.google.android.gms.oss.licenses.OssLicensesMenuActivity;
import com.google.android.material.navigation.NavigationView;
import com.google.android.material.snackbar.Snackbar;

import java.io.IOException;

import javax.annotation.Nullable;

import butterknife.BindView;
import butterknife.ButterKnife;
import io.pslab.BuildConfig;
import io.pslab.R;
import io.pslab.communication.CommunicationHandler;
import io.pslab.fragment.AboutUsFragment;
import io.pslab.fragment.FAQFragment;
import io.pslab.fragment.HomeFragment;
import io.pslab.fragment.InstrumentsFragment;
import io.pslab.fragment.PSLabPinLayoutFragment;
import io.pslab.others.CustomSnackBar;
import io.pslab.others.CustomTabService;
import io.pslab.others.InitializationVariable;
import io.pslab.others.ScienceLabCommon;
import io.pslab.receivers.USBDetachReceiver;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";

    @BindView(R.id.nav_view)
    NavigationView navigationView;
    @Nullable
    @BindView(R.id.drawer_layout)
    DrawerLayout drawer;
    @BindView(R.id.toolbar)
    Toolbar toolbar;

    View navHeader;
    private ImageView imgProfile;
    private TextView txtName;

    private ProgressDialog initialisationDialog;

    private CustomTabService customTabService;
    private CustomTabsServiceConnection customTabsServiceConnection;

    public static int navItemIndex = 0;

    private static final String TAG_DEVICE = "device";
    private static final String TAG_INSTRUMENTS = "instruments";
    private static final String TAG_ABOUTUS = "aboutUs";
    private static final String TAG_PINLAYOUT = "pinLayout";
    private static final String TAG_FAQ = "faq";
    private static String CURRENT_TAG = TAG_INSTRUMENTS;
    private String[] activityTitles;

    private final boolean shouldLoadHomeFragOnBackPress = true;
    private Handler mHandler;
    private ScienceLabCommon mScienceLabCommon;

    public boolean PSLabisConnected = false;

    InitializationVariable initialisationStatus;

    public static boolean hasPermission = false;
    private boolean receiverRegister = false;
    private UsbManager usbManager;
    private PendingIntent mPermissionIntent;
    private CommunicationHandler communicationHandler;
    private USBDetachReceiver usbDetachReceiver;
    private static final String ACTION_USB_PERMISSION = "com.android.example.USB_PERMISSION";
    private static final int TIME_INTERVAL = 2000;
    private long mBackPressed;
    private static MainActivity instance;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        ButterKnife.bind(this);

        initialisationStatus = new InitializationVariable();
        initialisationDialog = new ProgressDialog(this);
        initialisationDialog.setMessage(getString(R.string.initialising_wait));
        initialisationDialog.setIndeterminate(true);
        initialisationDialog.setCancelable(false);

        usbManager = (UsbManager) getSystemService(USB_SERVICE);

        customTabService = new CustomTabService(MainActivity.this, customTabsServiceConnection);

        mScienceLabCommon = ScienceLabCommon.getInstance();

        initialisationDialog.show();

        communicationHandler = new CommunicationHandler(usbManager);
        attemptToGetUSBPermission();

        PSLabisConnected = mScienceLabCommon.openDevice(communicationHandler);

        IntentFilter usbDetachFilter = new IntentFilter();
        usbDetachFilter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
        usbDetachReceiver = new USBDetachReceiver(this);
        registerReceiver(usbDetachReceiver, usbDetachFilter);

        setSupportActionBar(toolbar);
        mHandler = new Handler();

        navHeader = navigationView.getHeaderView(0);
        txtName = navHeader.findViewById(io.pslab.R.id.name);
        imgProfile = navHeader.findViewById(io.pslab.R.id.img_profile);
        activityTitles = getResources().getStringArray(io.pslab.R.array.nav_item_activity_titles);

        setPSLabVersionIDs();

        setUpNavigationView();
        initialisationDialog.dismiss();

        if (savedInstanceState == null) {
            navItemIndex = 0;
            CURRENT_TAG = TAG_INSTRUMENTS;
            loadHomeFragment();
        }
        instance = this;
    }

    private void loadHomeFragment() {
        selectNavMenu();
        setToolbarTitle(activityTitles[navItemIndex]);
        if (drawer != null && getSupportFragmentManager().findFragmentByTag(CURRENT_TAG) != null) {
            drawer.closeDrawers();
            return;
        }
        Runnable mPendingRunnable = new Runnable() {
            @Override
            public void run() {
                Fragment fragment = null;
                try {
                    fragment = getHomeFragment();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                FragmentTransaction fragmentTransaction = getSupportFragmentManager().beginTransaction();
                fragmentTransaction.setCustomAnimations(R.anim.fade_in,
                        R.anim.fade_out);
                fragmentTransaction.replace(R.id.frame, fragment, CURRENT_TAG);
                fragmentTransaction.commitAllowingStateLoss();
            }
        };
        if (mPendingRunnable != null) {
            mHandler.post(mPendingRunnable);
        }
        if (drawer != null) {
            drawer.closeDrawers();
            invalidateOptionsMenu();
        }
    }

    public static MainActivity getInstance() {
        return instance;
    }

    private Fragment getHomeFragment() throws IOException {
        switch (navItemIndex) {
            case 2:
                return HomeFragment.newInstance(ScienceLabCommon.scienceLab.isConnected(), ScienceLabCommon.scienceLab.isDeviceFound());
            case 5:
                return AboutUsFragment.newInstance();
            case 8:
                return FAQFragment.newInstance();
            default:
                return InstrumentsFragment.newInstance();
        }
    }

    private void setToolbarTitle(final CharSequence title) {
        final ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setTitle(title);
        }
    }

    private void unCheckAllMenuItems(Menu menu) {
        int size = menu.size();
        for (int i = 0; i < size; i++) {
            final MenuItem item = menu.getItem(i);
            item.setChecked(false);
        }
    }

    private void selectNavMenu() {
        int size_menu = navigationView.getMenu().size();
        for (int i = 0; i < size_menu; i++) {
            final MenuItem item = navigationView.getMenu().getItem(i);
            if (item.hasSubMenu()) {
                unCheckAllMenuItems(item.getSubMenu());
            } else {
                item.setChecked(false);
            }
        }
        switch (navItemIndex) {
            case 0:
            case 1:
            case 2:
                navigationView.getMenu().getItem(navItemIndex).setChecked(true);
                break;
            case 5:
                navigationView.getMenu().getItem(navItemIndex).setChecked(true);
                break;
            case 8:
                navigationView.getMenu().getItem(navItemIndex).setChecked(true);
                break;
            default:
                navigationView.getMenu().getItem(0).setChecked(true);
                break;
        }
    }

    private void setUpNavigationView() {
        navigationView.setNavigationItemSelectedListener(new NavigationView.OnNavigationItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(@NonNull MenuItem item) {
                switch (item.getItemId()) {
                    case R.id.nav_instruments:
                        navItemIndex = 0;
                        CURRENT_TAG = TAG_INSTRUMENTS;
                        break;
                    case R.id.nav_device:
                        navItemIndex = 2;
                        CURRENT_TAG = TAG_DEVICE;
                        break;
                    case R.id.nav_settings:
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        Intent intent = new Intent(MainActivity.this, SettingsActivity.class);
                        intent.putExtra("title", "Settings");
                        startActivity(intent);
                        return true;
                    case R.id.nav_about_us:
                        navItemIndex = 5;
                        CURRENT_TAG = TAG_ABOUTUS;
                        break;
                    case R.id.nav_documentation:
                        customTabService.launchUrl("https://docs.pslab.io/");
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        break;
                    case R.id.nav_rate:
                        customTabService.launchUrl("https://play.google.com/store/apps/details?id=io.pslab");
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        break;
                    case R.id.nav_help_feedback:
                        navItemIndex = 8;
                        CURRENT_TAG = TAG_FAQ;
                        break;
                    case R.id.nav_buy_pslab:
                        customTabService.launchUrl("https://pslab.io/shop/");
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        break;
                    case R.id.sensor_data_logger:
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        startActivity(new Intent(MainActivity.this, DataLoggerActivity.class));
                        break;
                    case R.id.nav_share_app:
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        Intent shareIntent = new Intent(Intent.ACTION_SEND);
                        shareIntent.setType("text/plain");
                        shareIntent.putExtra(Intent.EXTRA_SUBJECT, getResources().getString(R.string.app_name));
                        String shareMessage = "https://play.google.com/store/apps/details?id=" + BuildConfig.APPLICATION_ID;
                        shareIntent.putExtra(Intent.EXTRA_TEXT, shareMessage);
                        startActivity(shareIntent);
                        return true;
                    case R.id.nav_generate_config:
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        startActivity(new Intent(MainActivity.this, CreateConfigActivity.class));
                        break;
                    case R.id.nav_privacy_policy:
                        customTabService.launchUrl("https://pslab.io/privacy-policy/");
                        if (drawer != null) {
                            drawer.closeDrawers();
                        }
                        break;
                    case R.id.nav_third_party_libs:
                        OssLicensesMenuActivity.setActivityTitle(getString(R.string.third_party_libs));
                        startActivity(new Intent(MainActivity.this, OssLicensesMenuActivity.class));
                        break;
                    default:
                        navItemIndex = 0;
                }
                loadHomeFragment();
                return true;
            }
        });

        if (drawer != null) {
            ActionBarDrawerToggle actionBarDrawerToggle = new ActionBarDrawerToggle(this, drawer, toolbar, io.pslab.R.string.openDrawer, io.pslab.R.string.closeDrawer) {
                @Override
                public void onDrawerClosed(View drawerView) {
                    super.onDrawerClosed(drawerView);
                }

                @Override
                public void onDrawerOpened(View drawerView) {
                    super.onDrawerOpened(drawerView);
                }
            };
            drawer.setDrawerListener(actionBarDrawerToggle);
            actionBarDrawerToggle.syncState();
        }
    }

    private void setPSLabVersionIDs() {
        try {
            txtName.setText(scienceLab.getVersion());
        } catch (IOException e) {
            txtName.setText(getString(R.string.device_not_found));
        }
    }

    public void showFirmwareDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(R.string.legacy_title);
        builder.setCancelable(false);
        builder.setMessage(R.string.legacy_message);
        builder.setIcon(android.R.drawable.ic_dialog_alert);
        builder.setPositiveButton("OK", (dialog, which) -> dialog.dismiss());
        builder.create().show();

    }

    @Override
    public void onBackPressed() {
        Fragment fragment = getSupportFragmentManager().findFragmentById(R.id.frame);
        if (drawer != null && drawer.isDrawerOpen(GravityCompat.START)) {
            drawer.closeDrawers();
            return;
        }
        if (fragment instanceof HomeFragment && HomeFragment.isWebViewShowing) {
            ((HomeFragment) fragment).hideWebView();
            return;
        }
        if (shouldLoadHomeFragOnBackPress) {
            if (navItemIndex != 0 || CURRENT_TAG.equals(TAG_PINLAYOUT)) {
                navItemIndex = 0;
                CURRENT_TAG = TAG_INSTRUMENTS;
                loadHomeFragment();
                return;
            }
        }
        if (fragment instanceof InstrumentsFragment) {
            if (mBackPressed + TIME_INTERVAL > System.currentTimeMillis()) {
                super.onBackPressed();
                return;
            } else {
                CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                        getString(R.string.Toast_double_tap), null, null, Snackbar.LENGTH_SHORT);
            }
            mBackPressed = System.currentTimeMillis();
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.pslab_connectivity_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.menu_pslab_connected:
                CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                        getString(R.string.device_connected_successfully), null, null, Snackbar.LENGTH_SHORT);
                break;
            case R.id.menu_pslab_disconnected:
                attemptToConnectPSLab();
                break;
            case R.id.menu_pslab_layout_front:
                PSLabPinLayoutFragment.frontSide = true;
                displayPSLabPinLayout();
                break;
            case R.id.menu_pslab_layout_back:
                PSLabPinLayoutFragment.frontSide = false;
                displayPSLabPinLayout();
                break;
            default:
                break;
        }
        return true;
    }

    private void attemptToConnectPSLab() {
        initialisationDialog.show();
        mScienceLabCommon = ScienceLabCommon.getInstance();
        if (communicationHandler.isConnected()) {
            initialisationDialog.dismiss();
            CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                    getString(R.string.device_connected_successfully), null, null, Snackbar.LENGTH_SHORT);
        } else {
            communicationHandler = new CommunicationHandler(usbManager);
            if (communicationHandler.isDeviceFound()) {
                attemptToGetUSBPermission();
            } else {
                initialisationDialog.dismiss();
                CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                        getString(R.string.device_not_found), null, null, Snackbar.LENGTH_SHORT);
                navItemIndex = 2;
                CURRENT_TAG = TAG_DEVICE;
                loadHomeFragment();
            }
        }
    }

    private void displayPSLabPinLayout() {
        CURRENT_TAG = TAG_PINLAYOUT;
        navigationView.getMenu().getItem(navItemIndex).setChecked(false);
        setToolbarTitle(getResources().getString(R.string.pslab_pinlayout));
        Runnable mPendingRunnable = new Runnable() {
            @Override
            public void run() {
                Fragment fragment = PSLabPinLayoutFragment.newInstance();
                FragmentTransaction fragmentTransaction = getSupportFragmentManager().beginTransaction();
                fragmentTransaction.setCustomAnimations(R.anim.fade_in, R.anim.fade_out)
                        .replace(R.id.frame, fragment, TAG_PINLAYOUT)
                        .commitAllowingStateLoss();
            }
        };
        mHandler.post(mPendingRunnable);
    }

    private void attemptToGetUSBPermission() {
        if (!("android.hardware.usb.action.USB_DEVICE_ATTACHED".equals(getIntent().getAction()))) {
            if (communicationHandler.isDeviceFound() && !usbManager.hasPermission(communicationHandler.mUsbDevice)) {
                mPermissionIntent = PendingIntent.getBroadcast(this, 0, new Intent(ACTION_USB_PERMISSION), PendingIntent.FLAG_IMMUTABLE);
                IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
                registerReceiver(mUsbReceiver, filter);
                receiverRegister = true;
                usbManager.requestPermission(communicationHandler.mUsbDevice, mPermissionIntent);
            }
            if (communicationHandler.mUsbDevice != null) {
                if (usbManager.hasPermission(communicationHandler.mUsbDevice))
                    initialisationDialog.dismiss();
                hasPermission = true;
            }
        } else if (usbManager.hasPermission(communicationHandler.mUsbDevice)) {
            hasPermission = true;
            initialisationDialog.dismiss();
        }
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        menu.getItem(0).setVisible(PSLabisConnected);
        menu.getItem(1).setVisible(!PSLabisConnected);
        setPSLabVersionIDs();
        return true;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.v(TAG, "MainActivityDestroyed");
        try {
            scienceLab.disconnect();
        } catch (IOException e) {
            e.printStackTrace();
        }
        unregisterReceiver(usbDetachReceiver);
        if (customTabsServiceConnection != null) {
            this.unbindService(customTabsServiceConnection);
        }
        if (receiverRegister)
            unregisterReceiver(mUsbReceiver);
    }

    private final BroadcastReceiver mUsbReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (ACTION_USB_PERMISSION.equals(action)) {
                synchronized (this) {
                    UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        if (device != null) {
                            hasPermission = true;
                            PSLabisConnected = mScienceLabCommon.openDevice(communicationHandler);
                            initialisationDialog.dismiss();
                            invalidateOptionsMenu();
                            CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                                    getString(R.string.device_connected_successfully), null, null, Snackbar.LENGTH_SHORT);
                            if (navItemIndex == 0) {
                                getSupportFragmentManager().beginTransaction().replace(R.id.frame, InstrumentsFragment.newInstance()).commit();
                            } else if (navItemIndex == 2) {
                                getSupportFragmentManager().beginTransaction().replace(R.id.frame, HomeFragment.newInstance(true, true)).commitAllowingStateLoss();
                            } else {
                                CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                                        getString(R.string.device_connected_successfully), null, null, Snackbar.LENGTH_SHORT);
                            }
                        }
                    } else {
                        initialisationDialog.dismiss();
                        Log.d(TAG, "permission denied for device " + device);
                        CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                                getString(R.string.device_not_found), null, null, Snackbar.LENGTH_SHORT);
                    }
                }
            }
        }
    };

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        attemptToConnectPSLab();
        synchronized (this) {
            UsbDevice device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
            if (device != null && hasPermission) {
                PSLabisConnected = mScienceLabCommon.openDevice(communicationHandler);
                initialisationDialog.dismiss();
                invalidateOptionsMenu();
                if (navItemIndex == 0) {
                    getSupportFragmentManager().beginTransaction().replace(R.id.frame, InstrumentsFragment.newInstance()).commit();
                } else if (navItemIndex == 2) {
                    getSupportFragmentManager().beginTransaction().replace(R.id.frame, HomeFragment.newInstance(true, true)).commitAllowingStateLoss();
                }
                CustomSnackBar.showSnackBar(findViewById(android.R.id.content),
                        getString(R.string.device_connected_successfully), null, null, Snackbar.LENGTH_SHORT);
            }
        }
    }

    @Override
    protected void onPostResume() {
        super.onPostResume();
        selectNavMenu();
    }
}
