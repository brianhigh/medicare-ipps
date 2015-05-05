# ----------------------------------------------------------------------
# checkallpkgs.R
# ----------------------------------------------------------------------
#
# This script attempts to find all of the R packages used in all of the
# R script/presentation files in the current working folder and then 
# attempts to install the ones which are missing, then tries to load them 
# all into memory with "require". The intent is to ensure that any packages 
# required for the scripts to run have been installed previously by running
# this script first. 
#
# Usage: 
#
#   1. Use setwd() to set the working directory to the folder containing
#      the R script and R presentation files.
#
#   2. Run this command: source("checkallpkgs.R")
#      ... where you should use the actual file path to this script.
#
# Author: Brian High with contributions from Rafael Gottardo
# Date: 2015-05-04
# License: http://creativecommons.org/licenses/by-sa/3.0/deed.en_US

# ----------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------

# tryinstall() function
#     Conditionally install using install.packages() or biocLite()
#     Usage: tryinstall(c("package1", "package2", ...))
tryinstall <- function(p) {
    n <- p[!(p %in% installed.packages()[,"Package"])]
    if(length(n)) {
        install.packages(n, repos="http://cran.fhcrc.org") | {
            source("http://bioconductor.org/biocLite.R")
            biocLite(n, ask = FALSE)
        }
    }
}

# ----------------------------------------------------------------------
# Main Routine
# ----------------------------------------------------------------------

# Compile a list of Rpres and Rmd filenames in the current directory
# Tip: Use pattern="*.(Rpres|R|Rmd)" to also check *.R scripts.
filenames <- list.files(".", pattern="*.(Rpres|Rmd|R)$", full.names=FALSE)

# Parse each file to find the packages used and compile into a list
allpkgs <- c()
for (filename in filenames) {
    pkgs <- readLines(filename, warn = FALSE)
    pkgs <- unlist(strsplit(x = pkgs, split = ";[ ]*"))
    pkgs <- pkgs[grepl("(library|require|install\\.packages|biocLite)\\(", pkgs)]
    pkgs <- gsub(".*\\((.*)\\).*", "\\1", pkgs)
    pkgs <- unlist(strsplit(x = pkgs, split = ",[ ]*"))
    pkgs <- gsub('["()]', "", pkgs)
    pkgs <- unique(pkgs[!grepl("=", pkgs)])
    allpkgs <- c(allpkgs,pkgs)
}

# Remove duplicates and false-positives
allpkgs <- unique(allpkgs)
allpkgs <- allpkgs[!(allpkgs %in% c("n", "pkg", "pkgs"))]

# Save a copy of the package list
write(allpkgs, "packages_list.txt")

# Attempt to load or install the packages using the tryinstall function
tryinstall(allpkgs)

# Check that all packages will load
for (pkg in allpkgs) require(pkg, character.only = TRUE)

# Review any warnings and then clear any warnings
warnings()
assign("last.warning", NULL, envir = baseenv())
