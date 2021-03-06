#@desc Evaluate a series of candidate tracts for similarity to a reference tract. The
#@desc specified TractName must match that passed to the "hnt-ref" experiment used to
#@desc generate the reference tract. Source sessions for the candidate tracts are
#@desc given using the SessionList option. The SeedPointList is optional - if omitted
#@desc then the standard space seed point associated with the reference tract will be
#@desc used to establish neighbourhood centre points. Any candidate seed point with
#@desc anisotropy lower than AnisotropyThreshold will be ignored.

suppressPackageStartupMessages(require(tractor.session))
suppressPackageStartupMessages(require(tractor.nt))

runExperiment <- function ()
{
    tractName <- getConfigVariable("TractName", NULL, "character", errorIfMissing=TRUE)
    sessionList <- getConfigVariable("SessionList", NULL, "character", errorIfMissing=TRUE)
    seedList <- getConfigVariable("SeedPointList", NULL, "integer")
    pointType <- getConfigVariable("PointType", NULL, "character", validValues=c("fsl","r","mm"), errorIfInvalid=TRUE)
    searchWidth <- getConfigVariable("SearchWidth", 1)
    faThreshold <- getConfigVariable("AnisotropyThreshold", 0.2)
    nSamples <- getConfigVariable("NumberOfSamples", 1000)
    resultsName <- getConfigVariable("ResultsName", "results")
    
    reference <- getNTResource("reference", "hnt", list(tractName=tractName))
    nSessions <- length(sessionList)
    
    if (is.null(seedList))
        pointType <- "r"
    else
    {
        if (is.null(pointType))
            report(OL$Error, "Point type must be specified with the seed list")

        seedMatrix <- matrix(seedList, ncol=3, byrow=TRUE)

        if (pointType == "fsl")
            seedMatrix <- transformFslVoxelToRVoxel(seedMatrix)
    }

    results <- parallelApply(seq_len(nSessions), function (i) {
        currentSession <- newSessionFromDirectory(sessionList[i])

        if (exists("seedMatrix"))
            currentSeed <- seedMatrix[i,]
        else
            currentSeed <- getNativeSpacePointForSession(currentSession, reference$getStandardSpaceSeedPoint(), pointType=reference$getSeedUnit(), isStandard=TRUE)

        if (pointType == "mm")
            currentSeed <- transformWorldToRVoxel(currentSeed, newMriImageMetadataFromFile(currentSession$getImageFileNameByType("maskedb0")), useOrigin=TRUE)
        
        result <- runNeighbourhoodTractography(currentSession, currentSeed, reference$getTract(), faThreshold, searchWidth, nSamples=nSamples)
        return (result)
    })
    
    resultsObject <- newHeuristicNTResultsFromList(results)
    writeNTResource(resultsObject, "results", "hnt", list(resultsName=resultsName))
}
