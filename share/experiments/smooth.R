#@args image file, kernel width
#@desc Smooth an image using a Gaussian smoothing kernel. The kernel width may be specified using the standard deviation, sigma (WidthType:sd), or the full width at half maximum (WidthType:fwhm). If only one width value is specified then the kernel will be isotropic and have dimensionality equal to that of the image (unless the image has more than three dimensions, in which case it will be 3D). Otherwise the dimensionality of the kernel will be given by the number of values specified. Values can be unequal for an anisotropic kernel. Note that this script requires the native package "mmand", which can be installed from the main TractoR directory using "make install-native".

library(mmand)

runExperiment <- function ()
{
    requireArguments("image file", "kernel width")
    
    widthType <- getConfigVariable("WidthType", "sd", validValues=c("sd","fwhm"))
    widthUnit <- getConfigVariable("WidthUnit", "mm", validValues=c("mm","vox"))
    
    image <- newMriImageFromFile(Arguments[1])
    width <- splitAndConvertString(Arguments[-1], ",", "numeric", fixed=TRUE, errorIfInvalid=TRUE)
    
    if (length(width) == 1)
        width <- rep(width, min(3,image$getDimensionality()))
    if (widthType == "fwhm")
        width <- width / 2*sqrt(2*log(2))
    if (widthUnit == "mm")
    {
        if (is.na(image$getVoxelUnit()["spatial"]))
            multiplier <- 1
        else
            multiplier <- switch(image$getVoxelUnit()["spatial"], m=1000, mm=1, um=0.001)
        width <- width / abs(image$getVoxelDimensions()[1:length(width)] * multiplier)
    }
    
    report(OL$Info, "Smoothing with kernel of sigma (", implode(round(width,2),","), ") voxels")
    
    newImage <- newMriImageWithSimpleFunction(image, gaussianSmooth, sigma=width)
    fileName <- paste(Arguments[1], "smoothed", sep="_")
    writeMriImageToFile(newImage, fileName)
    
    invisible(NULL)
}
