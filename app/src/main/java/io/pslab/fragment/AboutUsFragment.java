package io.pslab.fragment;


import android.content.Intent;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import androidx.appcompat.app.AppCompatDelegate;
import androidx.fragment.app.Fragment;

import com.google.android.material.appbar.AppBarLayout;

import io.pslab.R;

import butterknife.BindView;
import butterknife.ButterKnife;
import mehdi.sakout.aboutpage.AboutPage;
import mehdi.sakout.aboutpage.Element;


public class AboutUsFragment extends Fragment {

    @BindView(R.id.appBarAnim)
    AppBarLayout appBarLayout;

    public static AboutUsFragment newInstance() {
        return new AboutUsFragment();
    }

    public AboutUsFragment() {
    }


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_about_us, container, false);
        simulateDayNight(3);
        ButterKnife.bind(this, view);
        View aboutPage = new AboutPage(getActivity())
                .isRTL(false)
                .setImage(R.drawable.logo200x200)
                .addWebsite("https://goo.gl/forms/sHlmRAPFmzcGQ27u2", getString(R.string.nav_report))
                .addItem(new Element(getString(R.string.version), R.drawable.ic_widgets_black_24dp))
                .setDescription(getString(R.string.about_us_description))
                .addGroup("Connect with us")
                .addEmail("pslab-fossasia@googlegroups.com")
                .addWebsite("https://pslab.io/")
                .addGitHub("fossasia?utf8=✓&q=pslab")
                .addFacebook("pslabio")
                .addItem(addX())
                .addYoutube("UCQprMsG-raCIMlBudm20iLQ")
                .addItem(addDevelopers())
                .create();

        appBarLayout.addView(aboutPage, -1);
        return view;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        return super.onOptionsItemSelected(item);
    }

    private void simulateDayNight(int currentSetting) {
        final int DAY = 0;
        final int NIGHT = 1;
        final int FOLLOW_SYSTEM = 3;

        int currentNightMode = getResources().getConfiguration().uiMode
                & Configuration.UI_MODE_NIGHT_MASK;
        if (currentSetting == DAY && currentNightMode != Configuration.UI_MODE_NIGHT_NO) {
            AppCompatDelegate.setDefaultNightMode(
                    AppCompatDelegate.MODE_NIGHT_NO);
        } else if (currentSetting == NIGHT && currentNightMode != Configuration.UI_MODE_NIGHT_YES) {
            AppCompatDelegate.setDefaultNightMode(
                    AppCompatDelegate.MODE_NIGHT_YES);
        } else if (currentSetting == FOLLOW_SYSTEM) {
            AppCompatDelegate.setDefaultNightMode(
                    AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM);
        }
    }

    private Element addDevelopers() {
        Element developersElement = new Element();
        developersElement.setTitle(getString(R.string.developers));
        developersElement.setIconDrawable(R.drawable.ic_user__24dp);
        developersElement.setOnClickListener(v -> {
            String url = getString(R.string.github_developers_link);
            if (!url.startsWith("http://") && !url.startsWith("https://")) {
                url = "https://" + url;
            }
            Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            startActivity(browserIntent);
        });
        return developersElement;
    }

    private Element addX() {
        Element xElement = new Element();
        xElement.setTitle(getString(R.string.follow_us_on_x));
        xElement.setIconDrawable(R.drawable.x_logo);
        xElement.setOnClickListener(v -> {
            String url = getString(R.string.x_profile_link);
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            startActivity(intent);
        });
        return xElement;
    }


}
