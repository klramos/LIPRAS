# LIPRAS Advanced Tutorial
This tutorial highlights the more advanced features of fitting diffraction data with LIPRAS. To learn more about the basics, start with [LIPRAS Basic Tutorial](???TODO).

In this tutorial, we are going to work with **.xrdml** files. Go to the [Resources](#resources) section for a list of sample files and download the data set containing [.xrdml file](link).

## Tips to remember before we start
1. First tip here
2. Second tip here
3. Blah blah blah


## Preparing the data set for a new fit

1. Load a new data set by going to the menu **File** > **New...** > **Dataset**, or by clicking **Browse**. For this tutorial, we will use the data set contained in the file **repeated scan_450ºC[1249].xrdml**.

    ![](./Menu-file-new-dataset.png)
    ![](/var/folders/sh/69ynnvq54qv_4rr_r4xg484m0000gn/T/com.skitch.skitch/DMD958BFEED-0BC8-47CA-8AC6-68FA2BE2E6C9/Pasted_Image_3_16_17__12_11_PM.png)
    
    ****NOTE:*** 
  
2. Keep the initial 2$\theta$ range of 36.012º for the minimum and 47.987º for the maximum. We're going to fit the two peaks at approximately 38.2º and 44.5º.

    ![](/var/folders/sh/69ynnvq54qv_4rr_r4xg484m0000gn/T/com.skitch.skitch/DMDD0F24BC7-8474-480D-BA32-33BF78AEC407/Pasted_Image_3_16_17__12_31_PM.png =200px)

3. Keep the default background model and polynomial order. <br> To learn more about the different background options, read the [background tutorial]().



4. Push the **Select Points** button and click inside the plot to select as many points as you want to consider them as background data. When you're done, press the **Enter** key on your keyboard to save the points or press **Escape** to cancel.
    ****_NOTE:_*** Always select more points than the polynomial order.
    
    ![](file://localhost/Users/klarissaramos/MATLAB-Drive/Lipras-user-guide/Pasted_Image_3_16_17__12_39_PM.png)

    ![](file://localhost/Users/klarissaramos/MATLAB-Drive/Lipras-user-guide/selecting%20bkgd%20points.png)

    ----
    
    ****_Checkpoint_***: The background fit should look similar to the one below:
    ![](/var/folders/sh/69ynnvq54qv_4rr_r4xg484m0000gn/T/com.skitch.skitch/DMDCC24C04F-7537-4EAA-ACBD-7B7B386000F9/LIPRAS__Line-Profile_Analysis_Software.png)

    ---

5. Go to the **Options** tab. The **Lab X-Ray** box was automatically checked because you imported a file with a .xrdml extension.

![](/var/folders/sh/69ynnvq54qv_4rr_r4xg484m0000gn/T/com.skitch.skitch/DMD554BED26-C0E7-49B3-B554-AC52B93CF7F2/LIPRAS__Line-Profile_Analysis_Software.png)

6. Increase the number of peaks to 2; the peak function table becomes visible if the number of peaks is greater than 0.






## Resources
* [.xrdml file]()