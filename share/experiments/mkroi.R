#@args session directory, centre point
#@desc Create an Analyze/NIfTI/MGH volume containing a cuboidal region of interest with fixed voxel width in all dimensions. A session directory must be specified in addition to the ROI centre point so that the script can identify the correct diffusion space to use. The output file name is set with the ROIName option.

suppressPackageStartupMessages(require(tractor.session))

runExperiment <- function ()
{
    requireArguments("session directory", "centre point")
    
    session <- newSessionFromDirectory(Arguments[1])
    
    centre <- splitAndConvertString(Arguments[-1], ",", "numeric", fixed=TRUE, errorIfInvalid=TRUE)
    if (!exists("centre") || length(centre) != 3)
        report(OL$Error, "Centre point must be given as a single vector in 3D space, comma or space separated")
    
    pointType <- getConfigVariable("PointType", NULL, "character", validValues=c("fsl","r","mm"), errorIfInvalid=TRUE, errorIfMissing=TRUE)
    isStandardPoint <- getConfigVariable("CentreInMNISpace", FALSE)
    
    width <- getConfigVariable("Width", 7)
    roiName <- getConfigVariable("ROIName", "roi")
    
    t2Image <- session$getImageByType("maskedb0")
    centre <- getNativeSpacePointForSession(session, centre, pointType, isStandardPoint)
    
    roiImage <- newMriImageAsShapeOverlay("block", t2Image, centre=round(centre), width=width)
    writeMriImageToFile(roiImage, roiName)
    
    invisible (NULL)
}
