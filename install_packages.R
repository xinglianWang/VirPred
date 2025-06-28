#' Install Required Dependencies for VirPred Package
#'
#' This function installs all required and suggested dependencies for the VirPred package.
#' It checks if each package is already installed and only installs missing ones.
#'
#' @param install_suggests Logical indicating whether to install suggested packages.
#'                        Default is TRUE. Set to FALSE to skip suggested packages.
#' @param repos The CRAN repository to use. Default is "https://cloud.r-project.org".
#' @param ... Additional arguments passed to install.packages().
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Install only required dependencies
#' install_virpred_deps(install_suggests = FALSE)
#'
#' # Install all dependencies (required + suggested)
#' install_virpred_deps()
#' }
install_dependencies <- function(install_suggests = TRUE,
                                 repos = "https://cloud.r-project.org",
                                 ...) {
  # Required packages from Imports
  options(timeout = 1800) 
  required_pkgs <- c(
    "GSVA >= 1.52.3",
    "msigdbr >= 24.1.0",  # Note: corrected from 'misgdbr' to 'msigdbr'
    "caret >= 6.0.94",
    "kernlab",
    "MLmetrics",
    "optparse",
    "doParallel",
    "foreach"
  )

  # Suggested packages
  suggested_pkgs <- c(
    "testthat"
  )

  # Combine packages based on user choice
  pkgs_to_install <- required_pkgs
  if (install_suggests) {
    pkgs_to_install <- c(pkgs_to_install, suggested_pkgs)
  }

  options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")) 
  options(BioC_mirror = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor")

  # Install Bioconductor packages first
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos = repos, ...)
  }

  # Install GSVA from Bioconductor
  if (!requireNamespace("GSVA", quietly = TRUE) ||
      packageVersion("GSVA") < "1.52.3") {
    BiocManager::install("GSVA", update = FALSE, ask = FALSE, ...)
  }

  # Install CRAN packages
  for (pkg in pkgs_to_install) {
    pkg_name <- strsplit(pkg, " ")[[1]][1]
    version_req <- ifelse(grepl(">=", pkg),
                          sub(".*>= ", "", pkg),
                          NA)

    # Skip if already installed and meets version requirement
    if (requireNamespace(pkg_name, quietly = TRUE)) {
      if (is.na(version_req)) next
          if (packageVersion(pkg_name) >= version_req) next
    }

    # Install from CRAN
    if (pkg_name %in% c("msigdbr", "caret","kernlab","MLmetrics", "optparse", "testthat","doParallel","foreach")) {
      install.packages(pkg_name, repos = repos, ...)
    }
  }

  message("\nAll dependencies installed successfully!")
  invisible(NULL)
}

install_dependencies()
