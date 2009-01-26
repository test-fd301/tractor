#@args session directory
#@desc Run tractography using one or more masks. Every nonzero voxel in the specified
#@desc SeedMaskFile will be used as a seed point for NumberOfSamples streamlines, and
#@desc the results combined. If any WaypointMaskFiles are specified, streamlines which
#@desc do not pass through ALL of the masks given will be ignored.

suppressPackageStartupMessages(require(tractor.session))

runExperiment <- function ()
{
    requireArguments("session directory")
    session <- newSessionFromDirectory(Arguments[1])
    
    nSamples <- getWithDefault("NumberOfSamples", 5000)
    seedMaskFile <- getWithDefault("SeedMaskFile", NULL, "character", errorIfInvalid=TRUE, errorIfMissing=TRUE)
    seedMaskInStandardSpace <- getWithDefault("SeedMaskInStandardSpace", FALSE)
    waypointMaskFiles <- getWithDefault("WaypointMaskFiles", NULL, "character", errorIfInvalid=TRUE)
    waypointMasksInStandardSpace <- getWithDefault("WaypointMasksInStandardSpace", FALSE)
        
    createImages <- getWithDefault("CreateImages", FALSE)
    tractName <- getWithDefault("TractName", "tract")
    vizThreshold <- getWithDefault("VisualisationThreshold", 0.01)
    showSeed <- getWithDefault("ShowSeedPoint", TRUE)
    
    seedMask <- newMriImageFromFile(seedMaskFile)
    if (seedMaskInStandardSpace)
        seedMask <- transformStandardSpaceImage(session, seedMask)
    
    if (is.null(waypointMaskFiles))
        result <- runProbtrackWithSession(session, mode="seedmask", seedMask=seedMask, requireImage=createImages, nSamples=nSamples)
    else
    {
        waypointMasks <- list()
        for (waypointFile in waypointMaskFiles)
        {
            waypointMask <- newMriImageFromFile(waypointFile)
            if (waypointMasksInStandardSpace)
                waypointMask <- transformStandardSpaceImage(session, waypointMask)
            waypointMasks <- c(waypointMasks, list(waypointMask))
        }
        
        result <- runProbtrackWithSession(session, mode="seedmask", seedMask=seedMask, waypointMasks=waypointMasks, requireImage=createImages, nSamples=nSamples)
    }
    
    if (createImages)
    {
        output(OL$Info, "Creating tract images")
        writeMriImageToFile(result$image, tractName)
        writePngsForResult(result, prefix=tractName, threshold=vizThreshold, showSeed=showSeed)
    }
    
    invisible (NULL)
}