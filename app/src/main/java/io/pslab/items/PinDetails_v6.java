package io.pslab.items;

public class PinDetails_v6 {
    private final String name;
    private final String description;
    private final int colorID;

    public PinDetails_v6(String name, String description, int colorID) {
        this.name = name;
        this.description = description;
        this.colorID = colorID;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }


    public int getColorID() {
        return colorID;
    }

}
