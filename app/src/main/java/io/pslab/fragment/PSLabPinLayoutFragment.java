package io.pslab.fragment;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.PointF;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.core.content.res.ResourcesCompat;
import androidx.fragment.app.Fragment;

import java.util.ArrayList;
import java.util.List;

import io.pslab.R;
import io.pslab.items.PinDetails;

public class PSLabPinLayoutFragment extends Fragment implements View.OnTouchListener {

    private final List<PinDetails> pinDetails = new ArrayList<>();

    private final Matrix matrix = new Matrix();
    private final Matrix savedMatrix = new Matrix();

    public static boolean frontSide = true;

    private static final int NONE = 0;
    private static final int DRAG = 1;
    private static final int ZOOM = 2;
    private int mode = NONE;

    private final PointF start = new PointF();
    private final PointF mid = new PointF();
    private float oldDist = 1f;

    private ImageView colorMap;

    private ImageView imgLayout;

    public static PSLabPinLayoutFragment newInstance() {
        return new PSLabPinLayoutFragment();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_pin_layout, container, false);
        imgLayout = view.findViewById(R.id.img_pslab_pin_layout);
        colorMap = view.findViewById(R.id.img_pslab_color_map);
        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        imgLayout.setImageDrawable(ResourcesCompat.getDrawable(getResources(),
                frontSide ? R.drawable.pslab_v5_front_layout : R.drawable.pslab_v5_back_layout, null));
        colorMap.setImageDrawable(ResourcesCompat.getDrawable(getResources(),
                frontSide ? R.drawable.pslab_v5_front_colormap : R.drawable.pslab_v5_back_colormap, null));
        imgLayout.setOnTouchListener(this);
        populatePinDetails();
    }

    @Override
    public void onPause() {
        super.onPause();
        imgLayout.setImageDrawable(null);
        colorMap.setImageDrawable(null);
        // Force garbage collection to avoid OOM on older devices.
        System.gc();
    }

    private void populatePinDetails() {
        pinDetails.add(new PinDetails(getString(R.string.pin_esp_name), getString(R.string.pin_esp_description), getColor(R.color.category_usb), getColor(R.color.pin_esp)));
        pinDetails.add(new PinDetails(getString(R.string.pin_rxd_name), getString(R.string.pin_rxd_description), getColor(R.color.category_communication), getColor(R.color.pin_rxd)));
        pinDetails.add(new PinDetails(getString(R.string.pin_txd_name), getString(R.string.pin_txd_description), getColor(R.color.category_communication), getColor(R.color.pin_txd)));
        pinDetails.add(new PinDetails(getString(R.string.pin_gnd_name), getString(R.string.pin_gnd_description), getColor(R.color.category_voltage), getColor(R.color.pin_gnd)));
        pinDetails.add(new PinDetails(getString(R.string.pin_si1_name), getString(R.string.pin_si1_description), getColor(R.color.category_wavegen), getColor(R.color.pin_si1)));
        pinDetails.add(new PinDetails(getString(R.string.pin_si2_name), getString(R.string.pin_si2_description), getColor(R.color.category_wavegen), getColor(R.color.pin_si2)));
        pinDetails.add(new PinDetails(getString(R.string.pin_sq1_name), getString(R.string.pin_sq1_description), getColor(R.color.category_wavegen), getColor(R.color.pin_sq1)));
        pinDetails.add(new PinDetails(getString(R.string.pin_sq2_name), getString(R.string.pin_sq2_description), getColor(R.color.category_wavegen), getColor(R.color.pin_sq2)));
        pinDetails.add(new PinDetails(getString(R.string.pin_sq3_name), getString(R.string.pin_sq3_description), getColor(R.color.category_wavegen), getColor(R.color.pin_sq3)));
        pinDetails.add(new PinDetails(getString(R.string.pin_sq4_name), getString(R.string.pin_sq4_description), getColor(R.color.category_wavegen), getColor(R.color.pin_sq4)));
        pinDetails.add(new PinDetails(getString(R.string.pin_la1_name), getString(R.string.pin_la1_description), getColor(R.color.category_wavegen), getColor(R.color.pin_la1)));
        pinDetails.add(new PinDetails(getString(R.string.pin_la2_name), getString(R.string.pin_la2_description), getColor(R.color.category_wavegen), getColor(R.color.pin_la2)));
        pinDetails.add(new PinDetails(getString(R.string.pin_la3_name), getString(R.string.pin_la3_description), getColor(R.color.category_wavegen), getColor(R.color.pin_la3)));
        pinDetails.add(new PinDetails(getString(R.string.pin_la4_name), getString(R.string.pin_la4_description), getColor(R.color.category_wavegen), getColor(R.color.pin_la4)));
        pinDetails.add(new PinDetails(getString(R.string.pin_ac1_name), getString(R.string.pin_ac1_description), getColor(R.color.category_oscilloscope), getColor(R.color.pin_ac1)));
        pinDetails.add(new PinDetails(getString(R.string.pin_ch1_name), getString(R.string.pin_ch1_description), getColor(R.color.category_oscilloscope), getColor(R.color.pin_ch1)));
        pinDetails.add(new PinDetails(getString(R.string.pin_ch2_name), getString(R.string.pin_ch2_description), getColor(R.color.category_oscilloscope), getColor(R.color.pin_ch2)));
        pinDetails.add(new PinDetails(getString(R.string.pin_ch3_name), getString(R.string.pin_ch3_description), getColor(R.color.category_oscilloscope), getColor(R.color.pin_ch3)));
        pinDetails.add(new PinDetails(getString(R.string.pin_chg_name), getString(R.string.pin_chg_description), getColor(R.color.category_oscilloscope), getColor(R.color.pin_chg)));
        pinDetails.add(new PinDetails(getString(R.string.pin_mic_name), getString(R.string.pin_mic_description), getColor(R.color.category_measurement), getColor(R.color.pin_mic)));
        pinDetails.add(new PinDetails(getString(R.string.pin_frq_name), getString(R.string.pin_frq_description), getColor(R.color.category_measurement), getColor(R.color.pin_frq)));
        pinDetails.add(new PinDetails(getString(R.string.pin_cap_name), getString(R.string.pin_cap_description), getColor(R.color.category_measurement), getColor(R.color.pin_cap)));
        pinDetails.add(new PinDetails(getString(R.string.pin_res_name), getString(R.string.pin_res_description), getColor(R.color.category_measurement), getColor(R.color.pin_res)));
        pinDetails.add(new PinDetails(getString(R.string.pin_vol_name), getString(R.string.pin_vol_description), getColor(R.color.category_measurement), getColor(R.color.pin_vol)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pcs_name), getString(R.string.pin_pcs_description), getColor(R.color.category_power_source), getColor(R.color.pin_pcs)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pv3_name), getString(R.string.pin_pv3_description), getColor(R.color.category_power_source), getColor(R.color.pin_pv3)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pv2_name), getString(R.string.pin_pv2_description), getColor(R.color.category_power_source), getColor(R.color.pin_pv2)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pv1_name), getString(R.string.pin_pv1_description), getColor(R.color.category_power_source), getColor(R.color.pin_pv1)));
        pinDetails.add(new PinDetails(getString(R.string.pin_scl_name), getString(R.string.pin_scl_description), getColor(R.color.category_communication), getColor(R.color.pin_scl)));
        pinDetails.add(new PinDetails(getString(R.string.pin_sda_name), getString(R.string.pin_sda_description), getColor(R.color.category_communication), getColor(R.color.pin_sda)));
        pinDetails.add(new PinDetails(getString(R.string.pin_vdd_name), getString(R.string.pin_vdd_description), getColor(R.color.category_voltage), getColor(R.color.pin_vdd)));
        pinDetails.add(new PinDetails(getString(R.string.pin_sta_name), getString(R.string.pin_sta_description), getColor(R.color.category_communication), getColor(R.color.pin_sta)));
        pinDetails.add(new PinDetails(getString(R.string.pin_vpl_name), getString(R.string.pin_vpl_description), getColor(R.color.category_voltage), getColor(R.color.pin_vpl)));
        pinDetails.add(new PinDetails(getString(R.string.pin_ena_name), getString(R.string.pin_ena_description), getColor(R.color.category_communication), getColor(R.color.pin_ena)));
        pinDetails.add(new PinDetails(getString(R.string.pin_vmi_name), getString(R.string.pin_vmi_description), getColor(R.color.category_voltage), getColor(R.color.pin_vmi)));
        pinDetails.add(new PinDetails(getString(R.string.pin_mcl_name), getString(R.string.pin_mcl_description), getColor(R.color.category_communication), getColor(R.color.pin_mcl)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pgm_name), getString(R.string.pin_pgm_description), getColor(R.color.category_communication), getColor(R.color.pin_pgm)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pgc_name), getString(R.string.pin_pgc_description), getColor(R.color.category_communication), getColor(R.color.pin_pgc)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pgd_name), getString(R.string.pin_pgd_description), getColor(R.color.category_communication), getColor(R.color.pin_pgd)));
        pinDetails.add(new PinDetails(getString(R.string.pin_nrf_name), getString(R.string.pin_nrf_description), getColor(R.color.category_usb), getColor(R.color.pin_nrf)));
        pinDetails.add(new PinDetails(getString(R.string.pin_usb_name), getString(R.string.pin_usb_description), getColor(R.color.category_usb), getColor(R.color.pin_usb)));
        pinDetails.add(new PinDetails(getString(R.string.pin_vcc_name), getString(R.string.pin_vcc_description), getColor(R.color.category_voltage), getColor(R.color.pin_vcc)));
        pinDetails.add(new PinDetails(getString(R.string.pin_pl5_name), getString(R.string.pin_pl5_description), getColor(R.color.category_voltage), getColor(R.color.pin_pl5)));
        pinDetails.add(new PinDetails(getString(R.string.pin_dpl_name), getString(R.string.pin_dpl_description), getColor(R.color.category_usb), getColor(R.color.pin_dpl)));
        pinDetails.add(new PinDetails(getString(R.string.pin_dmi_name), getString(R.string.pin_dmi_description), getColor(R.color.category_usb), getColor(R.color.pin_dmi)));
    }

    private int getColor(int colorId) {
        final Context context = getContext();
        return context == null ? 0 : context.getColor(colorId);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public boolean onTouch(View v, MotionEvent event) {
        ImageView view = (ImageView) v;
        view.setScaleType(ImageView.ScaleType.MATRIX);
        colorMap.setScaleType(ImageView.ScaleType.MATRIX);
        float scale;

        switch (event.getAction() & MotionEvent.ACTION_MASK) {
            case MotionEvent.ACTION_DOWN:
                matrix.set(view.getImageMatrix());
                savedMatrix.set(matrix);
                start.set(event.getX(), event.getY());
                mode = DRAG;
                break;

            case MotionEvent.ACTION_UP:
                colorMap.setDrawingCacheEnabled(true);
                Bitmap clickSpot = Bitmap.createBitmap(colorMap.getDrawingCache());
                colorMap.setDrawingCacheEnabled(false);
                try {
                    int pixel = clickSpot.getPixel((int) event.getX(), (int) event.getY());
                    for (PinDetails pin : pinDetails) {
                        if (pin.getColorID() == Color.rgb(Color.red(pixel), Color.green(pixel), Color.blue(pixel))) {
                            displayPinDescription(pin);
                        }
                    }
                } catch (IllegalArgumentException e) {/**/}
                break;

            case MotionEvent.ACTION_POINTER_DOWN:
                oldDist = spacing(event);
                if (oldDist > 5f) {
                    savedMatrix.set(matrix);
                    midPoint(mid, event);
                    mode = ZOOM;
                }
                break;

            case MotionEvent.ACTION_MOVE:
                if (mode == DRAG) {
                    matrix.set(savedMatrix);
                    matrix.postTranslate(event.getX() - start.x, event.getY() - start.y);
                } else if (mode == ZOOM) {
                    float newDist = spacing(event);
                    if (newDist > 5f) {
                        matrix.set(savedMatrix);
                        scale = newDist / oldDist;
                        matrix.postScale(scale, scale, mid.x, mid.y);
                    }
                }
                break;

            default:
                break;
        }

        view.setImageMatrix(matrix);
        colorMap.setImageMatrix(matrix);

        return true;
    }

    private void displayPinDescription(PinDetails pin) {
        final Activity activity = getActivity();

        if (activity == null) {
            return;
        }

        final AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        LayoutInflater inflater = getActivity().getLayoutInflater();
        View view = inflater.inflate(R.layout.pin_description_dialog, null);
        builder.setView(view);

        ImageView pinColor = view.findViewById(R.id.pin_category_color);
        pinColor.setBackgroundColor(pin.getCategoryColor());
        TextView pinTitle = view.findViewById(R.id.pin_description_title);
        pinTitle.setText(pin.getName());
        TextView pinDescription = view.findViewById(R.id.pin_description);
        pinDescription.setText(pin.getDescription());
        Button dialogButton = view.findViewById(R.id.pin_description_dismiss);

        builder.create();
        final AlertDialog dialog = builder.show();

        dialogButton.setOnTouchListener((v, event) -> {
            view.performClick();
            dialog.dismiss();
            return true;
        });
    }

    private float spacing(MotionEvent event) {
        float x = 0;
        float y = 0;
        try {
            x = event.getX(0) - event.getX(1);
            y = event.getY(0) - event.getY(1);
        } catch (Exception e) {/**/}
        return (float) Math.sqrt(x * x + y * y);
    }

    private void midPoint(PointF point, MotionEvent event) {
        float x = 0;
        float y = 0;
        try {
            x = event.getX(0) + event.getX(1);
            y = event.getY(0) + event.getY(1);
        } catch (Exception e) {/**/}
        point.set(x / 2, y / 2);
    }
}