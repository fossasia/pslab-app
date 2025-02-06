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
import io.pslab.items.PinDetails_v6;

public class PSLabPinLayoutFragment_v6 extends Fragment implements View.OnTouchListener {

    private final List<PinDetails_v6> pinDetails_v6 = new ArrayList<>();

    private final Matrix matrix = new Matrix();
    private final Matrix savedMatrix = new Matrix();

    public static boolean topside = true;

    private static final int NONE = 0;
    private static final int DRAG = 1;
    private static final int ZOOM = 2;
    private int mode = NONE;

    private final PointF start = new PointF();
    private final PointF mid = new PointF();
    private float oldDist = 1f;

    private ImageView colorMap;
    private ImageView imgLayout;

    public static PSLabPinLayoutFragment_v6 newInstance() {
        return new PSLabPinLayoutFragment_v6();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_pin_layout_v6, container, false);
        imgLayout = view.findViewById(R.id.img_pslab_pin_layout_v6);
        colorMap = view.findViewById(R.id.img_pslab_color_map_v6);
        return view;
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public void onResume() {
        super.onResume();
        imgLayout.setImageDrawable(ResourcesCompat.getDrawable(getResources(),
                topside ? R.drawable.pslab_v6_bottom : R.drawable.pslab_v6_top, null));
        colorMap.setImageDrawable(ResourcesCompat.getDrawable(getResources(),
                topside ? R.drawable.pslab_v6_bottom_colormap : R.drawable.pslab_v6_top_colormap, null));
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
        // Populate pinDetails with the required data
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.txd), getString(R.string.pin_txd_description), getColor(R.color.txd)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.cen), getString(R.string.cen_description), getColor(R.color.cen)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.vcc), getString(R.string.pin_vcc_description), getColor(R.color.vcc)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.gnd), getString(R.string.gnd_description), getColor(R.color.gnd)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.rxd), getString(R.string.pin_rxd_description), getColor(R.color.rxd)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.uart_tx), getString(R.string.uart_tx), getColor(R.color.uart_tx)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.uart_rx), getString(R.string.uart_rx), getColor(R.color.uart_rx)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sine_wave_1), getString(R.string.sine_wave_1_description), getColor(R.color.sine_wave_1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sine_wave_2), getString(R.string.sine_wave_2_description), getColor(R.color.sine_wave_2)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.square_wave_1), getString(R.string.square_wave_1_description), getColor(R.color.square_wave_1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.square_wave_2), getString(R.string.square_wave_2_description), getColor(R.color.square_wave_2)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.square_wave_3), getString(R.string.square_wave_3_description), getColor(R.color.square_wave_3)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.square_wave_3), getString(R.string.square_wave_4_description), getColor(R.color.square_wave_4)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.logic_analyzer_1), getString(R.string.logic_analyzer_1_description), getColor(R.color.logic_analyzer_1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.logic_analyzer_2), getString(R.string.logic_analyzer_2_description), getColor(R.color.logic_analyzer_2)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.logic_analyzer_3), getString(R.string.logic_analyzer_3_description), getColor(R.color.logic_analyzer_3)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.logic_analyzer_4), getString(R.string.logic_analyzer_4_description), getColor(R.color.logic_analyzer_4)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.ac_channel), getString(R.string.ac_channel), getColor(R.color.ac_channel)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.channel_1), getString(R.string.channel_1_description), getColor(R.color.channel_1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.channel_2), getString(R.string.channel_2_description), getColor(R.color.channel_2)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.channel_3), getString(R.string.channel_3_description), getColor(R.color.channel_3)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.ch3_gain_set), getString(R.string.ch3_gain_set_description), getColor(R.color.ch3_gain_set)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.microphone), getString(R.string.microphone_description), getColor(R.color.microphone)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.frequency_v6), getString(R.string.frequency_v6_description), getColor(R.color.frequency)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.capacitance), getString(R.string.capacitance_v6_description), getColor(R.color.capacitance)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pin_res_name), getString(R.string.pin_res_description), getColor(R.color.resistance)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pin_vol_name), getString(R.string.pin_vol_description), getColor(R.color.voltage)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pv1), getString(R.string.pv1_description), getColor(R.color.pv1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pv2), getString(R.string.pv2_description), getColor(R.color.pv2)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pv3), getString(R.string.pv3_description), getColor(R.color.pv3)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pcs),getString(R.string.pcs_description),getColor(R.color.pcs)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.chip_select), getString(R.string.chip_select_description), getColor(R.color.chip_select)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.cs1), getString(R.string.cs1_description), getColor(R.color.cs1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sdi), getString(R.string.sdi_description), getColor(R.color.sdi)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sck), getString(R.string.sck_description), getColor(R.color.sclk)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sdo), getString(R.string.sdo_description), getColor(R.color.sdo)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sda_for_i2c), getString(R.string.sda_for_i2c_description), getColor(R.color.sda)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.scl_for_i2c), getString(R.string.scl_for_i2c_description), getColor(R.color.scl)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pin_vdd_name), getString(R.string.pin_vdd_description), getColor(R.color.vdd)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.current_3ma), getString(R.string.current_3ma_description), getColor(R.color.current_3ma)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.plus_5v), getString(R.string.plus_5v_description), getColor(R.color.plus_5v)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.voltage_plus_minus_5_0v),getString(R.string.voltage_plus_minus_5_0v_description),getColor(R.color.plus_minus_5v)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.voltage_plus_3_3v),getString(R.string.voltage_plus_3_3v_description),getColor(R.color.plus_3_3v)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.voltage_0_3_3v),getString(R.string.voltage_0_3_3v_description),getColor(R.color.range_0_to_3_3v)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pgc), getString(R.string.pgc_description), getColor(R.color.pgc)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.pgd), getString(R.string.pgd_description), getColor(R.color.pgd)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.mclr), getString(R.string.mclr_description), getColor(R.color.mclr)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.mcl), getString(R.string.mcl_description), getColor(R.color.mclr)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.dp), getString(R.string.dp_description), getColor(R.color.dp)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.dm), getString(R.string.dm_description), getColor(R.color.dm)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.vusb), getString(R.string.vusb_description), getColor(R.color.vusb)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.si1), getString(R.string.pin_si1_description), getColor(R.color.si1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.si2), getString(R.string.pin_si2_description), getColor(R.color.si2)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.vol),getString(R.string.vol_description),getColor(R.color.vol)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.res),getString(R.string.res_description),getColor(R.color.res)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.cap),getString(R.string.cap_v6_description),getColor(R.color.cap)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.frequency),getString(R.string.frequency_v6_description),getColor(R.color.fqy)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.mic),getString(R.string.mic_description),getColor(R.color.mic)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.c3g),getString(R.string.c3g_description),getColor(R.color.c3g)));

        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sq1),getString(R.string.sq1_description),getColor(R.color.sq1)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sq2),getString(R.string.sq2_description),getColor(R.color.sq2)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sq3),getString(R.string.sq3_description),getColor(R.color.sq3)));
        pinDetails_v6.add(new PinDetails_v6(getString(R.string.sq4),getString(R.string.sq4_description),getColor(R.color.sq4)));

    }
    private int getColor(int colorId) {
        final Context context = getContext();
        return context == null ? 0 : context.getColor(colorId);
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        ImageView view = (ImageView) v;
        imgLayout.setImageMatrix(matrix);
        colorMap.setImageMatrix(matrix);
        float scale;

        Matrix colorMapMatrix = new Matrix();
        colorMapMatrix.set(colorMap.getImageMatrix());

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
                    for (PinDetails_v6 pin : pinDetails_v6) {
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

        return true;
    }

    private void displayPinDescription(PinDetails_v6 pinDetails_v6) {
        final Activity activity = getActivity();

        if (activity == null) {
            return;
        }

        final AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
        LayoutInflater inflater = getActivity().getLayoutInflater();
        View view = inflater.inflate(R.layout.pin_description_dialog, null);
        builder.setView(view);
        TextView pinTitle = view.findViewById(R.id.pin_description_title);
        pinTitle.setText(pinDetails_v6.getName());
        TextView pinDescription = view.findViewById(R.id.pin_description);
        pinDescription.setText(pinDetails_v6.getDescription());
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
        if (event.getPointerCount() < 2) return 0;
        float x = event.getX(0) - event.getX(1);
        float y = event.getY(0) - event.getY(1);
        return (float) Math.sqrt(x * x + y * y);
    }

    private void midPoint(PointF point, MotionEvent event) {
        if (event.getPointerCount() < 2) return;
        float x = event.getX(0) + event.getX(1);
        float y = event.getY(0) + event.getY(1);
        point.set(x / 2, y / 2);
    }
}
