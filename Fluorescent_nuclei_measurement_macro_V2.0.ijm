// Description:
// The Fluorescent_Nuclei_Measurements_Macro was designed for use in Fiji (ImageJ) to estimate a measure of GFP+ cells within a given cell population.
// This is acomplished by analysing the area of DAPI+ nuclei surrounded by cytoplasmic GFP versus the total area of all DAPI+ nuclei within a given ROI.
// Version 2.0, Last edit: 28-05-2020, Github: https://github.com/J-PTRson/Cell-Image-Analysis/


//###################
//###Configuration###
//###################
requires("1.53a"); //version of ImageJ tested on.

dapi_channel = NaN; //Define the color channels used for analysis to skip the dialog windows. Integers only.
gfp_channel = NaN;

dapi_min_threshold = NaN;  //// Define the Threshold limits for each channel to skip the dialog windows. Integers only, range 0-255 (for 8-bit). 
dapi_max_threshold = NaN;

gfp_min_threshold = NaN;
gfp_max_threshold = NaN;

save_path = NaN; // Define a default output directory to skip the dialog window e.g. ("C:\\Users\\Joshua\\Desktop\\Image_Analyse\\")


/////////////////////////////////////////////////////////////////////////////
////////////////////// INITIALIZATION //////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

if (is("composite") == 0) {
	exit("A composite-class image is required");
}

run("Rename...");		//Change if the file name contains any illegal filename characters like (? / , > < ), or if the file name is too long.

myTitle = getTitle();	//Gets image Title
selectImage(myTitle); 
getDimensions(width, height, channels, slices, frames);

if (File.isDirectory(save_path) == 0) {  							//Checks if an output directory was defined.
	save_path = getDirectory("Choose an Output Directory");
	print(save_path);
}

//run("Size...", "width=1024 height=1024 constrain average interpolation=Bilinear"); //Optional resize
run("Set Measurements...", "area display redirect=None decimal=3");
run("Duplicate...", "title=Duplicated duplicate"); // The original image will remain unchanged, the macro continues using a duplicate image.


/////////////////////////////////////////////////////////////////////////////
///////////////// IMAGE ENHANCEMENT ////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////


response = getBoolean("Do you want to apply linear contrast normalization?");  //If you awnser NO, no image enhancement will be performed. However, the Image name will be still modified to "Enhanced".

if (response == 1) {		
	selectImage("Duplicated"); 
	for (i=1; i<=channels; i++) {
		setSlice(i);
		run("Enhance Contrast...", "saturated=0.4 normalize");  //Modify these saturation levels if more/less contrast is preferded. Current value is ImageJ's default.
	}
}


run("Duplicate...", "title=Enhanced duplicate");


///////////////////////////////////////////////////////////////////////////
////////////////////////// ROI SELECTION /////////////////////////////////
/////////////////////////////////////////////////////////////////////////


setTool(3);                               			  //Freehand-selection tool 
selectImage("Enhanced"); 
waitForUser('Hey Buddy!^^', "Please select a region to examine, then press OK"); //wait for user action
selectImage("Enhanced");                              //make sure we have the same foreground image again
if (selectionType() != 3)                            //make sure we have got a freehand selection
	exit('Y U NO Select Region?!');


run("Create Mask");
run("Invert");
imageCalculator("Subtract create stack", "Enhanced","Mask");
run("Rename...", "title=Masked");
close("Mask");

selectWindow("Masked");
run("Rename...", "title=R.O.I");



///////////////////////////////////////////////////////////////////////////
///////////////////// CELL TYPE ANALYSIS /////////////////////////////////
/////////////////////////////////////////////////////////////////////////

if (isNaN(dapi_channel) || isNaN(gfp_channel)) { 

	Dialog.createNonBlocking("Quick Question?");
	Dialog.addMessage("Which channel numbers belong to DAPI & GFP?");
	Dialog.addNumber("DAPI Channel", 0);
	Dialog.addNumber("GFP Channel", 0);
	Dialog.show();
	dapi_channel = Dialog.getNumber() ; //Returns the contents of the next numeric field. 
	gfp_channel = Dialog.getNumber() ; //Returns the contents of the next numeric field. 

	if (dapi_channel == gfp_channel) {
		exit("The DAPI and GFP channels cannot be the same channel");
	}else if(dapi_channel < 1 || gfp_channel < 1) {
		exit("DAPI and GFP channels cannot be smaller than 1");
	}else if(dapi_channel > channels || gfp_channel > channels) {
		exit("DAPI and GFP channels cannot be larger than the total number of channels");
	}else if(isNaN(dapi_channel) || isNaN(gfp_channel)) {
		exit("DAPI and GFP channels need to be integers");
	}
}

selectWindow("R.O.I");
run("Split Channels");


////////////////////////////////////////////////////////////////////
//DAPI-channel//

selectWindow("C" + round(dapi_channel) + "-R.O.I");

run("Duplicate...", "title=DAPI");

if (isNaN(dapi_min_threshold) || isNaN(dapi_max_threshold)) { 
	run("Threshold...");
	waitForUser('Hey Buddy!^^', "Please determine a Threshold first, then press OK");
	getThreshold(dapi_min_threshold,dapi_max_threshold);
	close("Threshold");
}

setThreshold(dapi_min_threshold, dapi_max_threshold);
run("Convert to Mask");
run("Despeckle");
run("Watershed");

run("Analyze Particles...", "size=2-Infinity show=Nothing display add"); //Change these parameters as you see fit.


selectWindow("Duplicated");
run("RGB Color");
selectWindow("Duplicated (RGB)");
roiManager("Show All without labels");

//debug step//
//waitForUser("Debug: Click OK to continue the script."); selectWindow("Duplicated (RGB)"); roiManager("Show All without labels");  //Use these commands to pause the code for visual inspection at this stage.

run("Flatten");
selectWindow("Duplicated (RGB)-1");
saveAs("Jpeg", save_path + myTitle + "_DAPI+_Nuclei.jpg");
close("Duplicated (RGB)");
close("ROI Manager");
selectWindow("Duplicated (RGB)-1");
rename("DAPI+_Nuclei");


////////////////////////////////////////////////////////////////////
//GFP-channel//

selectWindow("C" + round(gfp_channel) + "-R.O.I");

run("Duplicate...", "title=GFP");

if (isNaN(gfp_min_threshold) || isNaN(gfp_max_threshold)) { 
	run("Threshold...");
	waitForUser('Hey Buddy!^^', "Please determine a Threshold first, then press OK");
	getThreshold(gfp_min_threshold,gfp_max_threshold);
	close("Threshold");
}

setThreshold(gfp_min_threshold, gfp_max_threshold);
run("Convert to Mask");
run("Despeckle");
run("Options...", "iterations=1 count=1 do=Close");
run("Options...", "iterations=1 count=1 do=[Fill Holes]");

imageCalculator("AND", "GFP","DAPI"); // This step filters for the DAPI nuclei of GFP+ cells.

run("Despeckle");
run("Watershed");
run("Analyze Particles...", "size=2-Infinity show=Nothing display add");//Change these parameters as you see fit.


selectWindow("Duplicated");
run("RGB Color");
selectWindow("Duplicated (RGB)");
roiManager("Show All without labels");  //shows all detected nuclei.

//debug step//
//waitForUser("Debug: Click OK to continue the script."); selectWindow("Duplicated (RGB)"); roiManager("Show All without labels");  //Use these commands to pause the code for visual inspection at this stage.

run("Flatten"); //burns the selection into the image.
selectWindow("Duplicated (RGB)-1");
saveAs("Jpeg", save_path + myTitle + "_cytoGFP+_Nuclei.jpg");
close("Duplicated (RGB)");
close("ROI Manager");

selectWindow("Duplicated (RGB)-1");
rename("cytoGFP+_Nuclei");


/////////////////////////////////////////////////////////////////
//No-Overlay//

selectWindow("Duplicated");
run("RGB Color");
selectWindow("Duplicated (RGB)");
saveAs("Jpeg", save_path + myTitle + "_No_Overlay.jpg");
close("Duplicated (RGB)");


///////////////////////////////////////////////////////////////////////////
///////////////////// CLOSE DOWN WINDOWS /////////////////////////////////
/////////////////////////////////////////////////////////////////////////


for (i=1; i<=channels; i++) {
		close("C"+ i +"-R.O.I");
}

close("DAPI");
close("GFP");
close("Duplicated");
close("Enhanced");

//close("cytoGFP+_Nuclei");
//close("DAPI+_Nuclei");
//close(myTitle);

saveAs("Results", save_path + myTitle + ".csv");
//close("Results");

waitForUser('Hey Buddy!^^', "The Macro has Finished!"); //wait for user action
