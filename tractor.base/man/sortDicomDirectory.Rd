\name{sortDicomDirectory}
\alias{sortDicomDirectory}
\title{Sort a directory of DICOM files into series}
\description{
  This function sorts a directory containing DICOM files into subdirectories by series number, DICOM tag (0x0020,0x0011), and/or subject name, DICOM tag (0x0010,0x0010). Each unique identifier, together with its description, will be used as the name for a new subdirectory of the specified top-level directory, and all relevant files will be copied into that subdirectory. Duplicate file names are disambiguated if necessary.
}
\usage{
sortDicomDirectory(directory, deleteOriginals = FALSE, sortOn = "series")
}
\arguments{
  \item{directory}{A length-1 character vector giving the directory to search for DICOM files. Subdirectories will also be searched.}
  \item{deleteOriginals}{A single logical value. If \code{TRUE}, then the source files will be deleted after being copied to their new locations, making the operation a move rather than a copy. Nothing will be deleted if the copy fails.}
  \item{sortOn}{Either \code{"series"} or \code{"subject"}, or both in the order desired. This will be the basis of the sort, which will be nested if both types are specified.}
}
\value{
  This function is called for its side effect.
}
\author{Jon Clayden}
\references{
Please cite the following reference when using TractoR in your work:

J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A. Clark (2011). TractoR: Magnetic resonance imaging and tractography with R. Journal of Statistical Software 44(8):1-18. \url{http://www.jstatsoft.org/v44/i08/}.
}
\seealso{\code{\link{newMriImageFromDicom}} for reading DICOM files into an \code{MriImage} object.}
