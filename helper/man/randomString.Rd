% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mxMisc.R
\name{randomString}
\alias{randomString}
\title{Random string generator}
\usage{
randomString(prefix = NULL, suffix = NULL, n = 15, sep = "_",
  addSymbols = F, addLetters = T, splitIn = 5, splitSep = "-")
}
\arguments{
\item{prefix}{Prefix. Default = NULL}

\item{suffix}{Suffix. Default = NULL}

\item{n}{Number of character to include in the random string}

\item{sep}{Separator for prefix or suffix}

\item{addSymbols}{Add random symbols}

\item{addLetters}{Add random letters (upper and lowercase)}

\item{splitIn}{Split string into chunk, with separator as defined in splitSep}

\item{splitSep}{Split symbos if splitIn > 1}
}
\value{
Random string of letters, with prefix and suffix
}
\description{
Create a random string with optional settings.
}

