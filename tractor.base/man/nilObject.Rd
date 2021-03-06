\name{nilObject}
\alias{nilObject}
\alias{is.nilObject}
\title{The nil object}
\description{
  The nil object is an empty object of class \code{\link{SerialisableObject}}. It can be used as a placeholder where such an object of this class, or one of its subclasses, is required. It serialises to the empty list.
}
\usage{
nilObject()
is.nilObject(object)
}
\arguments{
  \item{object}{Any object.}
}
\value{
\code{nilObject} returns the nil object. \code{is.nilObject} returns \code{TRUE} if its argument is identical to the nil object, or if it is equivalent in the sense of serialising to an identical result.
}
\author{Jon Clayden}
\references{
Please cite the following reference when using TractoR in your work:

J.D. Clayden, S. Muñoz Maniega, A.J. Storkey, M.D. King, M.E. Bastin & C.A. Clark (2011). TractoR: Magnetic resonance imaging and tractography with R. Journal of Statistical Software 44(8):1-18. \url{http://www.jstatsoft.org/v44/i08/}.
}
\seealso{\code{\link{SerialisableObject}}}
