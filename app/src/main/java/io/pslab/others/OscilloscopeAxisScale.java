package io.pslab.others;

import java.util.ArrayList;
import java.util.Collection;

/**
 * Encapsulates axis scale values of the Oscilloscope.
 */
public class OscilloscopeAxisScale {

    public static final float DEFAULT_X_AXIS_SCALE = 875f;
    public static final float DEFAULT_Y_AXIS_SCALE = 16f;

    private final Collection<AxisScaleSetListener> axisScaleSetListeners = new ArrayList<>();

    private double xAxisScale = DEFAULT_X_AXIS_SCALE;
    private double leftYAxisScaleUpper = DEFAULT_Y_AXIS_SCALE;
    private double leftYAxisScaleLower = -DEFAULT_Y_AXIS_SCALE;
    private double rightYAxisScaleUpper = DEFAULT_Y_AXIS_SCALE;
    private double rightYAxisScaleLower = -DEFAULT_Y_AXIS_SCALE;

    /**
     * Adds a new listener which will be informed when a range value is changed.
     *
     * @param listener the listener to add
     */
    public void addAxisScaledListener(AxisScaleSetListener listener) {
        if (listener != null) {
            axisScaleSetListeners.add(listener);
        }
    }

    /**
     * Removes a listener which will be informed when a range value is changed.
     *
     * @param listener the listener to remove
     */
    public void removeAxisScaledListener(AxisScaleSetListener listener) {
        axisScaleSetListeners.remove(listener);
    }

    /**
     * Gets scale of X-axis.
     *
     * @return the scale value
     */
    public double getXAxisScale() {
        return xAxisScale;
    }

    /**
     * Sets sccale of the X-axis.
     *
     * @param timebase the scale value
     */
    public void setXAxisScale(double timebase) {
        this.xAxisScale = timebase;

        for (AxisScaleSetListener listener : axisScaleSetListeners) {
            listener.onXAxisScaleSet(timebase);
        }
    }

    /**
     * Gets upper value of scale on the left Y-axis.
     *
     * @return the scale value
     */
    public double getLeftYAxisScaleUpper() {
        return leftYAxisScaleUpper;
    }

    /**
     * Gets lower value of scale on the left Y-axis.
     *
     * @return the scale value
     */
    public double getLeftYAxisScaleLower() {
        return leftYAxisScaleLower;
    }

    /**
     * Sets upper and lower limit of the left Y-axis. The lower limit is the input value multiplied by -1.
     *
     * @param limit new scale value, must be positive
     */
    public void setLeftYAxisScale(double limit) {
        setLeftYAxisScale(limit, -limit);
    }

    /**
     * Sets upper and lower limit of the left Y-axis. The lower limit must be smaller than the upper limit.
     *
     * @param upperLimit new upper scale value
     * @param lowerLimit new lower scale value
     */
    public void setLeftYAxisScale(double upperLimit, double lowerLimit) {
        if (upperLimit < lowerLimit) {
            throw new IllegalArgumentException(String.format("Upper limit (%f) must be larger than lower limit (%f).",
                    upperLimit, lowerLimit));
        }

        this.leftYAxisScaleUpper = upperLimit;
        this.leftYAxisScaleLower = lowerLimit;

        for (AxisScaleSetListener listener : axisScaleSetListeners) {
            listener.onLeftYAxisScaleSet(upperLimit, lowerLimit);
        }
    }

    /**
     * Gets upper value of scale on the right Y-axis.
     *
     * @return the scale value
     */
    public double getRightYAxisScaleUpper() {
        return rightYAxisScaleUpper;
    }

    /**
     * Gets lower value of scale on the right Y-axis.
     *
     * @return the scale value
     */
    public double getRightYAxisScaleLower() {
        return rightYAxisScaleLower;
    }

    /**
     * Sets upper and lower limit of the right Y-axis. The lower limit is the input value multiplied by -1.
     *
     * @param limit new scale value, must be positive
     */
    public void setRightYAxisScale(double limit) {
        setRightYAxisScale(limit, -limit);
    }

    /**
     * Sets upper and lower limit of the right Y-axis. The lower limit must be smaller than the upper limit.
     *
     * @param upperLimit new upper scale value
     * @param lowerLimit new lower scale value
     */
    public void setRightYAxisScale(double upperLimit, double lowerLimit) {
        if (upperLimit < lowerLimit) {
            throw new IllegalArgumentException(String.format("Upper limit (%f) must be larger than lower limit (%f).",
                    upperLimit, lowerLimit));
        }

        this.rightYAxisScaleUpper = upperLimit;
        this.rightYAxisScaleLower = lowerLimit;

        for (AxisScaleSetListener listener : axisScaleSetListeners) {
            listener.onRightYAxisScaleSet(upperLimit, lowerLimit);
        }
    }

    /**
     * Listener which is called when axis scale is set.
     */
    public interface AxisScaleSetListener {

        /**
         * Called when scale of the X-axis is set.
         *
         * @param timebase new scale value
         */
        void onXAxisScaleSet(double timebase);

        /**
         * Called when scale of the left Y-axis is set.
         *
         * @param upperLimit new upper scale value
         * @param lowerLimit new lower scale value
         */
        void onLeftYAxisScaleSet(double upperLimit, double lowerLimit);

        /**
         * Called when scale of the right Y-axis is set.
         *
         * @param upperLimit new upper scale value
         * @param lowerLimit new lower scale value
         */
        void onRightYAxisScaleSet(double upperLimit, double lowerLimit);
    }
}
