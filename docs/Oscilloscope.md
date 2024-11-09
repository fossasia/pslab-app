# How to use oscilloscope

## Table of Content
1. Introduction
2. Layout
3. Features and Components
    - *Channel Parameters*
    - *Timebase and Trigger*
    - *Data analysis*
    - *XY Plot*
4. How to Use  

## Introduction
Pocket Science Lab contains an oscilloscope which has lot of functions which are available in a commercial grade oscilloscope. The PSLab android application communicates with the Pocket Science Lab and gives the user a real experience on using a commercial oscilloscope. This document will help a user on available functionalities and how to use Pocket Science Lab with PSLab android application.  

## Layout

The layout of the oscilloscope graphical user interface contains three main parts. 
1. Graph plot
2. Function Navigation bar
3. Functions

<table>
    <tr>
        <td><img src="/docs/images/instrument_oscilloscope_channelparam.png"></td>
        <td><img src="/docs/images/instrument_oscilloscope_dataanalysis.png"></td>
    </tr>
</table>
<table>
    <tr>
        <td><img src="/docs/images/instrument_oscilloscope_timebase.png"></td>
        <td><img src="/docs/images/instrument_oscilloscope_xyplot.png"></td>
    </tr>
</table>

## Features and Components
Available features in Pocket Science Lab regarding oscilloscope are,
    - 4 channels up to 2MSPS
    - 2x Sine Wave Generators
    - 4x PWM generators. 15nS resolution. Up to 8MHz


Component | Name in the device
--- | ---
Channels | CH1, CH2, CH3, MIC
Ground | GND

These features can be used using four components in the oscilloscope. Note that GND is common for all the pins in the device.

### 1. Channel Parameters
Channel parameters can be used to select the following settings.
- *Channel/s* that needs to be observerd
- *Voltage range* or *Amplitude* in the graph plot 

When the check boxes selected from the items below the graph plot, user will be able to find the live plotting of the input read through the relevant channel. 
For `CH1` and `CH2`, user can adjust the voltage range/amplitude of the graphs 'y axis' using the drop down menus next to the check boxes. 
The `MIC` can be used to read either internal microphone or external microphone. 

### 2. Timebase and Trigger
Timebase parameter is used to change the range of 'x axis' which is Time. By increasing the 'Timebase' using the seekbar, longer waves can be captured. 
Trigger takes two parameters `channel` and `voltage`. When the read voltage of the selected channel exceeds the selected value for voltage, a trigger occurs.

### 3. Data Analysis
This function is to fit the read data series into,
1. Sine function
2. Square function
3. Fourier transform

When the oscilloscope reads an input, user can find out the closest sine/square function for the observed data input using this section.  

### 4. XY Plot
Using this graph, user can determine the behaviour of one channel input against another channel input. So x and y axes both shows a voltage value of the two channels.  

## How to Use

The input pins for the oscilloscope are the Channel pins and MIC. 

### Observing external waves

A `channel pin` from PSLab device must be connected to the `positive pin` of the signal generator which you want to analyze. Use any of the `ground pins` in PSLab device to connect the `negative/ground pin` of the signal generator.

### Observing waves from the in-built Wavegenerator instrument  

Using the *Wavegenerator*, set values to Sine, Square or Trangular waves. Then the relevant pin you used should be connected to any of the channels. 
For example, Let's generate a Sine wave. Set the frequency using Wavegenerator by selecting Sine wave 1. Additionally you can change the phase of the wave. Then connect the Channel 1 to the Sine wave as shown below.

<img src="/docs/images/oscilloscope_schematic.png">

Open oscilloscope and in the `Channel parameters` section, set the check boxes `CH1`. You can observe the waves plotting. 
Using `Timebase`, observe the plot changes when time range is increased. Similarly set Sine wave 2 frequency and phase and connect the `SI2` pin to `CH2`. Check tick box `CH2` in the `Channel parameters` and observe the two waves simultaneously. Go to `XY plot` section and tick the `Enable XY plot` checkbox. Observe the channel to channel voltage plot.
