StreamlineTractMetadata <- setRefClass("StreamlineTractMetadata", contains="SerialisableObject", fields=list(originAtSeed="logical",coordUnit="character",imageMetadata="MriImageMetadata"), methods=list(
    initialize = function (...)
    {
        object <- initFields(...)
        if (length(object$coordUnit) > 0 && !isTRUE(object$coordUnit %in% c("vox","mm")))
            report(OL$Error, "Coordinate unit must be \"vox\" (for voxels) or \"mm\" (for millimetres)")
        
        return (object)
    },
    
    getCoordinateUnit = function () { return (coordUnit) },
    
    getImageMetadata = function () { return (imageMetadata) },
    
    getSpatialRange = function () { report(OL$Error, "Method \"getSpatialRange\" undefined") },
    
    isOriginAtSeed = function () { return (originAtSeed) }
))

StreamlineTract <- setRefClass("StreamlineTract", contains="StreamlineTractMetadata", fields=list(line="matrix",seedIndex="integer",originalSeedPoint="numeric",pointSpacings="numeric"), methods=list(
    initialize = function (line = matrix(), seedIndex = NULL, originalSeedPoint = NULL, metadata = NULL, ...)
    {
        if (!is.null(metadata))
            import(metadata, "StreamlineTractMetadata")
        else
            callSuper(...)
        
        object <- initFields(line=line, seedIndex=seedIndex, originalSeedPoint=originalSeedPoint)

        if (dim(object$line)[2] != 3)
            report(OL$Error, "Streamline must be specified as a matrix with 3 columns")        
        object$pointSpacings <- apply(diff(object$line), 1, vectorLength)
        
        return (object)
    },
    
    getLine = function () { return (line) },
    
    getLineLength = function () { return (sum(pointSpacings)) },
    
    getMetadata = function () { return (export("StreamlineTractMetadata")) },
    
    getPointSpacings = function () { return (pointSpacings) },
    
    getSeedIndex = function () { return (seedIndex) },
    
    getOriginalSeedPoint = function () { return (originalSeedPoint) },
    
    getSeedPoint = function () { return (originalSeedPoint) },
    
    getSpatialRange = function ()
    {
        fullRange <- apply(line, 2, range, na.rm=TRUE)
        return (list(mins=fullRange[1,], maxes=fullRange[2,]))
    },
    
    nPoints = function () { return (dim(line)[1]) }
))

StreamlineSetTract <- setRefClass("StreamlineSetTract", contains="StreamlineTractMetadata", fields=list(seedPoint="numeric",leftLengths="integer",rightLengths="integer",leftPoints="array",rightPoints="array"), methods=list(
    initialize = function (..., metadata = NULL)
    {
        if (!is.null(metadata))
            import(metadata, "StreamlineTractMetadata")
        return (initFields(...))
    },
    
    getLeftLengths = function () { return (leftLengths) },
    
    getLeftPoints = function () { return (leftPoints) },
    
    getMetadata = function () { return (export("StreamlineTractMetadata")) },
    
    getRightLengths = function () { return (rightLengths) },
    
    getRightPoints = function () { return (rightPoints) },
    
    getSeedPoint = function () { return (seedPoint) },
    
    getSpatialRange = function ()
    {
        leftRange <- apply(leftPoints, 2, range, na.rm=TRUE)
        rightRange <- apply(rightPoints, 2, range, na.rm=TRUE)
        mins <- pmin(leftRange,rightRange)[1,]
        maxes <- pmax(leftRange,rightRange)[2,]
        return (list(mins=mins, maxes=maxes))
    },
    
    nStreamlines = function () { return (dim(leftPoints)[3]) }
))

newStreamlineTractMetadataFromImageMetadata <- function (imageMetadata, originAtSeed, coordUnit)
{
    tractMetadata <- StreamlineTractMetadata$new(originAtSeed=originAtSeed, coordUnit=coordUnit, imageMetadata=imageMetadata)
    invisible (tractMetadata)
}

newStreamlineSetTractFromProbtrack <- function (session, x, y = NULL, z = NULL, nSamples = 5000, maxPathLength = NULL, rightwardsVector = NULL)
{
    probtrackResult <- runProbtrackWithSession(session, x, y, z, requireParticlesDir=TRUE, nSamples=nSamples, verbose=TRUE, force=TRUE)
    
    seed <- probtrackResult$seed
    axisNames <- c("left-right", "anterior-posterior", "inferior-superior")
    
    if (is.null(maxPathLength))
    {
        fileSizes <- particleFileSizesForResult(probtrackResult)
        maxPathLength <- round(max(fileSizes) / 20)
        report(OL$Info, "Setting maximum path length to ", maxPathLength)
    }
    
    if (!is.null(rightwardsVector) && (!is.numeric(rightwardsVector) || length(rightwardsVector) != 3))
    {
        flag(OL$Warning, "Rightwards vector specified is not a numeric 3-vector - ignoring it")
        rightwardsVector <- NULL
    }
    
    subSize <- ifelse(nSamples < 40, nSamples, ceiling(nSamples / 20))
    
    if (is.null(rightwardsVector))
    {
        subData <- array(NA, dim=c(maxPathLength,3,subSize))
        report(OL$Info, "Reading subset of ", subSize, " streamlines")

        for (i in 1:subSize)
        {
            sampleData <- retrieveProbtrackStreamline(probtrackResult, i)
            len <- length(sampleData[,1])

            if (len > maxPathLength)
            {
                report(OL$Warning, "Path length for streamline ", i, " is too long (", len, "); truncating")
                len <- maxPathLength
            }

            subData[1:len,,i] <- sampleData[1:len,]
        }

        # The estimated rightwards direction is the mean first step
        firstSteps <- subData[2,,] - subData[1,,]
        rightwardsVector <- apply(abs(firstSteps), 1, mean)
        
        # Remove the subsample to save memory
        rm(subData)
    }
    
    report(OL$Info, "Rightwards vector is (", implode(round(rightwardsVector,2),","), ")")
    
    leftLengths <- numeric(0)
    rightLengths <- numeric(0)
    leftData <- array(NA, dim=c(maxPathLength,3,nSamples))
    rightData <- array(NA, dim=c(maxPathLength,3,nSamples))
    report(OL$Info, "Reading data from ", nSamples, " streamlines...")
    
    # Read all the data in, separating out "left" and "right" streamline parts
    for (i in 1:nSamples)
    {       
        sampleData <- retrieveProbtrackStreamline(probtrackResult, i)
        len <- length(sampleData[,1])
        
        # If any streamline is too long, we have to truncate it
        if (len > maxPathLength)
        {
            report(OL$Warning, "Path length for streamline ", i, " (", len, ") is too long; truncating")
            len <- maxPathLength
        }
        
        startRows <- which(sampleData[,1]==seed[1] & sampleData[,2]==seed[2] & sampleData[,3]==seed[3])
        
        # The seed point should appear exactly twice in each file, but it
        # occasionally appears twice in succession for some unknown reason
        # The following "paragraph" is a hack to fix this problem
        repeats <- which(diff(startRows) == 1) + 1
        for (rep in repeats)
        {
            sampleData <- sampleData[-startRows[rep],]
            startRows <- startRows[-rep]
            len <- len - 1
        }
        
        if (length(startRows) != 2)
            report(OL$Error, "Seed point appears ", length(startRows), " times (expecting 2) in streamline ", i)
        restartRow <- startRows[2]
        if (restartRow > len)
            report(OL$Error, "Left and right line components do not appear within the specified maximum path length")
        
        rightSideInnerProduct <- (sampleData[2,]-sampleData[1,]) %*% rightwardsVector
        if (rightSideInnerProduct == 0)
            flag(OL$Warning, "Tract is orthogonal to the left-right separation plane")
        
        if (rightSideInnerProduct <= 0)
        {
            leftLengths <- c(leftLengths, (restartRow-1))
            rightLengths <- c(rightLengths, (len-restartRow+1))
            leftData[1:(restartRow-1),,i] <- sampleData[1:(restartRow-1),]
            rightData[1:(len-restartRow+1),,i] <- sampleData[restartRow:len,]
        }
        else
        {
            rightLengths <- c(rightLengths, (restartRow-1))
            leftLengths <- c(leftLengths, (len-restartRow+1))
            rightData[1:(restartRow-1),,i] <- sampleData[1:(restartRow-1),]
            leftData[1:(len-restartRow+1),,i] <- sampleData[restartRow:len,]
        }
        
        if (i %% subSize == 0)
            report(OL$Verbose, "Done ", i)
    }
    
    t2Metadata <- newMriImageMetadataFromFile(session$getImageFileNameByType("maskedb0"))
    metadata <- newStreamlineTractMetadataFromImageMetadata(t2Metadata, FALSE, "vox")
    
    tract <- StreamlineSetTract$new(seedPoint=seed, leftLengths=leftLengths, rightLengths=rightLengths, leftPoints=leftData, rightPoints=rightData, metadata=metadata)
    invisible (tract)
}

newStreamlineSetTractBySubsetting <- function (tract, indices)
{
    if (!is(tract, "StreamlineSetTract"))
        report(OL$Error, "The specified tract is not a StreamlineSetTract object")
    if (length(indices) < 1)
        report(OL$Error, "At least one streamline must be included in the subset")
    
    leftLengths <- tract$getLeftLengths()[indices]
    rightLengths <- tract$getRightLengths()[indices]
    leftPoints <- tract$getLeftPoints()[,,indices,drop=FALSE]
    rightPoints <- tract$getRightPoints()[,,indices,drop=FALSE]
    
    newTract <- StreamlineSetTract$new(seedPoint=tract$getSeedPoint(), leftLengths=leftLengths, rightLengths=rightLengths, leftPoints=leftPoints, rightPoints=rightPoints, metadata=tract$getMetadata())
    invisible (newTract)
}

newStreamlineSetTractFromStreamline <- function (tract)
{
    if (!is(tract, "StreamlineTract"))
        report(OL$Error, "The specified tract is not a StreamlineTract object")
    
    line <- tract$getLine()
    
    leftLength <- tract$getSeedIndex()
    rightLength <- nrow(line) - leftLength + 1
    leftPoints <- line[leftLength:1,]
    rightPoints <- line[leftLength:nrow(line),]
    dim(leftPoints) <- c(dim(leftPoints), 1)
    dim(rightPoints) <- c(dim(rightPoints), 1)
    
    newTract <- StreamlineSetTract$new(seedPoint=tract$getSeedPoint(), leftLengths=leftLength, rightLengths=rightLength, leftPoints=leftPoints, rightPoints=rightPoints, metadata=tract$getMetadata())
    invisible (newTract)
}

newStreamlineSetTractByTruncationToReference <- function (tract, reference, testSession)
{
    if (!is(tract, "StreamlineSetTract"))
        report(OL$Error, "The specified tract is not a StreamlineSetTract object")
    if (!is(reference,"ReferenceTract") || !is(reference$getTract(),"BSplineTract"))
        report(OL$Error, "The specified reference tract is not valid")
    
    # Transform the reference tract into native space, find its length in this
    # space, and use that to truncate the streamline set
    refSession <- reference$getSourceSession()
    refPoints <- getPointsForTract(reference$getTract(), reference$getTractOptions()$pointType)
    
    if (reference$getTractOptions()$registerToReference)
    {
        if (is.null(refSession))
            transform <- getMniTransformForSession(testSession)
        else
            transform <- newAffineTransform3DFromFlirt(refSession$getImageFileNameByType("maskedb0"), testSession$getImageFileNameByType("maskedb0"))
    
        refPoints$points <- transformWorldPointsWithAffine(transform, refPoints$points)
    }
    
    refSteps <- calculateStepVectors(refPoints$points, refPoints$seedPoint)
    refLeftLength <- sum(apply(refSteps$left,1,vectorLength), na.rm=TRUE)
    refRightLength <- sum(apply(refSteps$right,1,vectorLength), na.rm=TRUE)
    
    # Estimate the step length from the mean of the first ten gaps in the first streamline
    testPoints <- tract$getLeftPoints()[1:10,,1]
    if (tract$getCoordinateUnit() == "vox")
        testPoints <- transformRVoxelToWorld(testPoints, tract$getImageMetadata())
    realStepLength <- mean(apply(diff(testPoints), 1, vectorLength), na.rm=TRUE)
    report(OL$Info, "Step length in streamline set is ", signif(realStepLength,3), " mm")
    
    maxPointsLeft <- ceiling(refLeftLength / realStepLength)
    maxPointsRight <- ceiling(refRightLength / realStepLength)
    
    leftLengths <- pmin(maxPointsLeft, tract$getLeftLengths())
    rightLengths <- pmin(maxPointsRight, tract$getRightLengths())
    leftPoints <- tract$getLeftPoints()[1:max(leftLengths),,,drop=FALSE]
    rightPoints <- tract$getRightPoints()[1:max(rightLengths),,,drop=FALSE]
    
    newTract <- StreamlineSetTract$new(seedPoint=tract$getSeedPoint(), leftLengths=leftLengths, rightLengths=rightLengths, leftPoints=leftPoints, rightPoints=rightPoints, metadata=tract$getMetadata())
    invisible (newTract)
}

newStreamlineTractWithMetadata <- function (tract, metadata)
{
    if (!is(tract, "StreamlineTract"))
        report(OL$Error, "The specified tract is not a valid StreamlineTract object")
    if (!is(metadata, "StreamlineTractMetadata"))
        report(OL$Error, "The specified metadata object is not valid")
    if (!equivalent(tract$getImageMetadata()$getVoxelDimensions(), metadata$getImageMetadata()$getVoxelDimensions(), signMatters=FALSE))
        report(OL$Error, "Can't change voxel dimensions at the moment")
    
    line <- tract$getLine()
    seed <- tract$getOriginalSeedPoint()
    imageMetadata <- tract$getImageMetadata()
    
    if (tract$isOriginAtSeed())
        line <- transformWithTranslation(line, seed)
    
    # Coordinate unit from voxels to millimetres
    if (tract$getCoordinateUnit() == "vox" && metadata$getCoordinateUnit() == "mm")
    {
        line <- transformRVoxelToWorld(line, imageMetadata)
        seed <- transformRVoxelToWorld(seed, imageMetadata)
    }
    else if (tract$getCoordinateUnit() == "mm" && metadata$getCoordinateUnit() == "vox")
    {
        line <- transformWorldToRVoxel(line, imageMetadata)
        seed <- transformWorldToRVoxel(seed, imageMetadata)
    }
    
    if (metadata$isOriginAtSeed())
        line <- transformWithTranslation(line, -seed)
    
    newTract <- newStreamlineTractFromLine(line, tract$getSeedIndex(), seed, metadata)
    invisible (newTract)
}

newStreamlineTractFromLine <- function (line, seedIndex, originalSeedPoint, metadata)
{
    streamline <- StreamlineTract$new(line=line, seedIndex=seedIndex, originalSeedPoint=originalSeedPoint, metadata=metadata)
    invisible (streamline)
}

newStreamlineTractFromSet <- function (tract, method = c("median","single"), originAtSeed = NULL, lengthQuantile = NULL, index = NULL)
{
    if (!is(tract, "StreamlineSetTract"))
        report(OL$Error, "The specified tract is not a valid StreamlineSetTract object")
    if (is.null(originAtSeed))
        originAtSeed <- tract$isOriginAtSeed()
    
    method <- match.arg(method)
    
    if (method == "median")
    {
        if (is.null(lengthQuantile))
            report(OL$Error, "Length quantile must be specified for the \"median\" method")
        
        leftLength <- floor(quantile(tract$getLeftLengths(), probs=lengthQuantile, names=FALSE))
        rightLength <- floor(quantile(tract$getRightLengths(), probs=lengthQuantile, names=FALSE))
        
        leftLine <- apply(tract$getLeftPoints()[1:leftLength,,], 1:2, median, na.rm=TRUE)
        rightLine <- apply(tract$getRightPoints()[1:rightLength,,], 1:2, median, na.rm=TRUE)
    }
    else if (method == "single")
    {
        if (is.null(index))
            report(OL$Error, "Index must be specified for the \"single\" method")
        
        leftLength <- tract$getLeftLengths()[index]
        rightLength <- tract$getRightLengths()[index]
        
        leftLine <- tract$getLeftPoints()[1:leftLength,,index]
        rightLine <- tract$getRightPoints()[1:rightLength,,index]
    }
    
    # Reverse the order of points in the first line part and append it to the
    # second line part, to create the complete median line
    # The first instance of the seed point is removed to avoid duplication
    if (leftLength < 2)
        fullLine <- rightLine
    else
        fullLine <- rbind(leftLine[leftLength:2,], rightLine)
    
    newTract <- newStreamlineTractFromLine(fullLine, leftLength, tract$getSeedPoint(), tract$getMetadata())
    finalMetadata <- StreamlineTractMetadata$new(originAtSeed=originAtSeed, coordUnit="mm", imageMetadata=tract$getImageMetadata())
    newTract <- newStreamlineTractWithMetadata(newTract, finalMetadata)
    
    rm(tract)
    invisible (newTract)
}

newStreamlineTractByTransformation <- function (tract, transform)
{
    if (!is(tract, "StreamlineTract"))
        report(OL$Error, "The specified tract is not a valid StreamlineTract object")
    
    oldSeed <- tract$getOriginalSeedPoint()
    oldLine <- tract$getLine()
    
    if (tract$isOriginAtSeed())
        oldLine <- transformWithTranslation(oldLine, oldSeed)
    
    useVoxels <- (tract$getCoordinateUnit() == "vox")
    newSeed <- transformPointsWithAffine(transform, oldSeed, useVoxels=useVoxels)
    newLine <- transformPointsWithAffine(transform, oldLine, useVoxels=useVoxels)
    
    if (tract$isOriginAtSeed())
        newLine <- transformWithTranslation(newLine, -newSeed)

    newTract <- newStreamlineTractFromLine(newLine, tract$getSeedIndex(), newSeed, tract$getMetadata())
    invisible (newTract)
}

newStreamlineTractWithSpacingThreshold <- function (tract, maxSeparation)
{
    if (!is(tract, "StreamlineTract"))
        report(OL$Error, "The specified tract is not a valid StreamlineTract object")
    
    line <- tract$getLine()
    spacings <- tract$getPointSpacings()
    seedPoint <- tract$getSeedIndex()
    nPoints <- tract$nPoints()
    
    wide <- which(spacings > maxSeparation)
    leftWide <- wide[which(wide < seedPoint)]
    rightWide <- wide[which(wide > seedPoint)]
    
    # The following are sensitive to the exact form of the output of
    # StreamlineTract$getPointSpacings() - at present, there is no leading NA
    # in the spacing vector, so spacings[1] is the distance *from* the first
    # point on the line
    leftStop <- ifelse(length(leftWide) > 0, max(leftWide)+1, 1)
    rightStop <- ifelse(length(rightWide) > 0, min(rightWide), nPoints)
    
    if (!identical(c(leftStop,rightStop), c(1,nPoints)))
        flag(OL$Info, "Truncating streamline to avoid large space between points")
    
    newTract <- newStreamlineTractFromLine(line[leftStop:rightStop,], (seedPoint-leftStop+1), tract$getOriginalSeedPoint(), tract$getMetadata())
    invisible (newTract)
}

newStreamlineTractWithCurvatureThreshold <- function (tract, maxAngle, isRadians = FALSE)
{
    if (!is(tract, "StreamlineTract"))
        report(OL$Error, "The specified tract is not a valid StreamlineTract object")
    
    if (!isRadians)
        maxAngle <- maxAngle / 180 * pi
    
    line <- tract$getLine()
    seedPoint <- tract$getSeedIndex()
    nPoints <- tract$nPoints()
    steps <- characteriseStepVectors(line, seedPoint)
    
    leftSharp <- which(steps$leftAngles > maxAngle)
    rightSharp <- which(steps$rightAngles > maxAngle)
    
    leftStop <- ifelse(length(leftSharp) > 0, max(leftSharp), 1)
    rightStop <- ifelse(length(rightSharp) > 0, min(rightSharp)-1, nPoints)
    
    if (!identical(c(leftStop,rightStop), c(1,nPoints)))
        report(OL$Info, "Truncating streamline to avoid sharp curvature")
    
    newTract <- newStreamlineTractFromLine(line[leftStop:rightStop,], (seedPoint-leftStop+1), tract$getOriginalSeedPoint(), tract$getMetadata())
    invisible (newTract)
}

newStreamlineTractByTrimming <- function (tract, trimLeft, trimRight)
{
    if (!is(tract, "StreamlineTract"))
        report(OL$Error, "The specified tract is not a valid StreamlineTract object")
    if (tract$getCoordinateUnit() != "mm")
        report(OL$Error, "This function requires a tract which uses a world coordinate system")
    
    line <- tract$getLine()
    spacings <- tract$getPointSpacings()
    
    leftSum <- cumsum(spacings)
    rightSum <- cumsum(rev(spacings))
    
    leftStop <- ifelse(max(leftSum) > trimLeft, min(which(leftSum > trimLeft))+1, 1)
    rightStop <- tract$nPoints() - ifelse(max(rightSum) > trimRight, min(which(rightSum > trimRight)), 0)
    
    newTract <- newStreamlineTractFromLine(line[leftStop:rightStop,], (tract$getSeedIndex()-leftStop+1), tract$getOriginalSeedPoint(), tract$getMetadata())
    invisible (newTract)
}

rescalePoints <- function (points, newUnit, metadata, seed)
{
    oldUnit <- metadata$getCoordinateUnit()
    imageMetadata <- metadata$getImageMetadata()
    
    if (!is.null(newUnit) && (newUnit != oldUnit))
    {
        if (metadata$isOriginAtSeed())
            points <- transformWithTranslation(points, seed)

        if (oldUnit == "vox" && newUnit == "mm")
        {
            points <- transformRVoxelToWorld(points, imageMetadata)
            seed <- transformRVoxelToWorld(seed, imageMetadata)
        }
        else if (oldUnit == "mm" && newUnit == "vox")
        {
            points <- transformWorldToRVoxel(points, imageMetadata)
            seed <- transformWorldToRVoxel(seed, imageMetadata)
        }

        if (metadata$isOriginAtSeed())
            points <- transformWithTranslation(points, -seed)
    }
    
    invisible (list(seed=seed, points=points))
}

getAxesForStreamlinePlot <- function (x, unit = NULL, axes = NULL, drawAxes = FALSE)
{
    if (is.null(unit))
        unit <- x$getCoordinateUnit()
    
    report(OL$Info, "Calculating plot range")
    range <- x$getSpatialRange()
    rescaledMaxes <- rescalePoints(range$maxes, unit, x$getMetadata(), x$getSeedPoint())
    rescaledMins <- rescalePoints(range$mins, unit, x$getMetadata(), x$getSeedPoint())
    range$maxes <- rescaledMaxes$points
    range$mins <- rescaledMins$points
    
    if (is.null(axes))
    {
        rangeWidths <- range$maxes - range$mins
        axes <- setdiff(1:3, which.min(rangeWidths))
    }
    
    if (length(axes) != 2)
        report(OL$Error, "Exactly two axes must be specified")
    
    axisNames <- c("left-right", "anterior-posterior", "inferior-superior")
    xlim <- c(range$mins[axes[1]], range$maxes[axes[1]])
    ylim <- c(range$mins[axes[2]], range$maxes[axes[2]])
    
    if (drawAxes)
    {
        xlab <- paste(axisNames[axes[1]], " (", unit, ")", sep="")
        ylab <- paste(axisNames[axes[2]], " (", unit, ")", sep="")
        plot(NA, xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab, asp=1)
    }
    
    return(axes)
}

plot.StreamlineTract <- function (x, y = NULL, unit = NULL, axes = NULL, add = FALSE, ...)
{
    if (!add)
        axes <- getAxesForStreamlinePlot(x, unit, axes, drawAxes=TRUE)
    else if (is.null(axes))
        report(OL$Error, "Axes must be specified if adding to an existing plot")
    
    line <- x$getLine()
    rescaledLine <- rescalePoints(line, unit, x$getMetadata(), x$getSeedPoint())
    lines(rescaledLine$points[,axes[1]], rescaledLine$points[,axes[2]], ...)
    
    invisible (axes)
}

plot.StreamlineSetTract <- function (x, y = NULL, unit = NULL, axes = NULL, add = FALSE, ...)
{
    if (!add)
        axes <- getAxesForStreamlinePlot(x, unit, axes, drawAxes=TRUE)
    else if (is.null(axes))
        report(OL$Error, "Axes must be specified if adding to an existing plot")
    
    report(OL$Info, "Plotting streamlines")
    leftPoints <- x$getLeftPoints()
    rightPoints <- x$getRightPoints()
    
    for (i in 1:x$nStreamlines())
    {
        ll <- rescalePoints(leftPoints[,,i], unit, x$getMetadata(), x$getSeedPoint())
        rl <- rescalePoints(rightPoints[,,i], unit, x$getMetadata(), x$getSeedPoint())
        lines(ll$points[,axes[1]], ll$points[,axes[2]], ...)
        lines(rl$points[,axes[1]], rl$points[,axes[2]], ...)
    }
    
    if (x$isOriginAtSeed())
        seed <- rep(0,3)
    else
        seed <- x$getSeedPoint()
    
    points(seed[axes[1]], seed[axes[2]], col="red", pch=19)
    
    invisible (axes)
}