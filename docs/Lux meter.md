# How to use Lux meter

## Table of Content
1. Introduction
2. Layout
3. Features
    - *Data*
    - *Configure*
4. How to Use  

## Introduction
Pocket Science Lab contains a lux meter which can measure real time ambient light intensity. This lux meter can use either the `built-in ambient light sensor` in your android device, `BH-1750` or `TSL-2561` lux sensors. The PSLab android application communicates with the Pocket Science Lab using `I2C` bus to read the two externally connected sensors. This document will help a user on available functionalities and how to use Pocket Science Lab with PSLab android application.  

## Layout

The layout of the oscilloscope graphical user interface contains two main parts. 
1. Data view
2. Configuration

<table>
    <tr>
        <td><img src="/docs/images/instrument_luxmeter_guide.png"></td>
        <td><img src="/docs/images/instrument_luxmeter_view.png"></td>
    </tr>
</table>
<table>
    <tr>
        <td><img src="/docs/images/instrument_luxmeter_config.png"></td>
        <td><img src="/docs/images/view_datalogger_play.png"></td>
    </tr>
</table>

## Features
In the lux meter there are two views that you can navigate to using a bottom navigation bar. 

### Data
Data view is to display the light value read from either the built-in sensor or I2C connected lux sensor. This view consist with a value guage, chart plot and a statistic panel. Statistics shows the maximum, minimum and average lux values.

### Configure
Configure view is used to control the lux meter by changing variuos parameters.
1. Select sensor
    - Used to select between sensors built-in, BH-1750 and TSL-2561
2. Gain range
    - When using sensors via PSLab device, can change the gain of the sensor to amplify the signal captured from the sensor. For the BH-1750 can select from `500`, `1000` and `4000`. For the TSL-2561 can choose from `1` and `16`. 
3. High limit
    - User can set a limit to high value of lux so that when it exceeds, the guage will notify using a red indicator. 
4. Update period
    - The time delay between two successive sensor readings can be changed by this parameter. The range is from `100ms` to `1000ms`.  

## How to Use

The default sensor for the lux meter is the built-in sensor. If the android device contains the ambient light sensor, immediatly the data can be observed throught the data view. 
When using a I2C connected lux sensor, the pin configuration for the sensor is as follows.

Pin in sensor | Pin in PSLab
--- | ---
VCC/VIN | VDD
GND | GND
SCL | SCL
SDA | SDA

<img src="/docs/images/bh1750_schematic.png"> 

The pin configuration for the TSL-2561 is also as same as above.

Change the parameters `update period`, `high limit` and `gain range` and observe the differences.