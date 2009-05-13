\name{NeighbourhoodInfo}
\alias{NeighbourhoodInfo}
\alias{info.neighbourhood}
\alias{createNeighbourhoodInfo}
\alias{isNeighbourhoodInfo}
\title{Class representing a cuboidal neighbourhood in an image}
\description{
  This class represents a cuboidal region of an image, with a centre and a fixed voxel width.
}
\usage{
createNeighbourhoodInfo(width, dim = 3, centre = rep(0, dim))
isNeighbourhoodInfo(object)
}
\arguments{
  \item{width}{An integer voxel width. Must be odd.}
  \item{dim}{An integer giving the dimensionality of the neighbourhood. Currently must be 3.}
  \item{centre}{A numeric vector giving the centre voxel of the neighbourhood. Must have exactly \code{dim} elements.}
  \item{object}{Any object.}
}
\value{
  \code{createNeighbourhoodInfo} returns a list with class \code{c("info.neighbourhood", "list")} and elements
  \item{width}{Copied from the \code{width} argument.}
  \item{dim}{Copied from the \code{dim} argument.}
  \item{centre}{Copied from the \code{centre} argument.}
  \item{vectors}{\code{dim} x \code{width}^\code{dim} matrix whose columns give the locations of each point in the neighbourhood.}
  \item{innerProducts}{A square, symmetric matrix of inner products between every location in the neighbourhood and every other.}
  
  \code{isNeighbourhoodInfo} returns TRUE if \code{object} is a NeighbourhoodInfo object, and FALSE otherwise.
}
\author{Jon Clayden}