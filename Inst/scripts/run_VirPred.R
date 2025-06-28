#!/usr/bin/env Rscript

# Load required packages
suppressPackageStartupMessages({
  library(optparse)
  library(VirPred)
})

# Set up command line options
option_list <- list(
  make_option(c("-i", "--input"), 
              type = "character", 
              help = "Path to expression data file (CSV/TSV) with genes as rows and samples as columns",
              metavar = "FILE"),
  
  make_option(c("-f", "--format"),
              type = "character",
              default = "Normalize",
              help = "Data format type:
              - 'Normalize' (default): For normalized data (log2TPM, log2FPKM, etc.)
              - 'Counts': For raw RNA-Seq counts",
              metavar = "{Normalize|Counts}"),
  
  make_option(c("-o", "--output"),
              type = "character",
              default = getwd(),
              help = "Output directory path (default: current directory)",
              metavar = "DIR"),
  
  make_option(c("-p", "--prefix"),
              type = "character",
              default = "VirPred_results",
              help = "Output file prefix (default: 'VirPred_results')",
              metavar = "PREFIX")

 )
  


# Create option parser
opt_parser <- OptionParser(
  usage = "VirPred [options]",
  option_list = option_list,
  description = "Virulence Prediction Tool: Predicts virulence from gene expression data.",
  epilogue = "Example:\n  VirPred -i data.csv -f Counts -o ./results"
  )

# Parse arguments
opts <- tryCatch(
  {
    parse_args(opt_parser)
  },
  error = function(e) {
    print_help(opt_parser)
    stop("\nError in command line arguments: ", e$message, call. = FALSE)
  }
)

opts <- tryCatch(
  {
    parse_args(opt_parser)
  },
  error = function(e) {
    print_help(opt_parser)
    stop("\nError in command line arguments: ", e$message, call. = FALSE)
  }
)

# Show help if requested
if (opts$help) {
  print_help(opt_parser)
  quit(status = 0)
}

# Validate required arguments
if (is.null(opts$input)) {
  print_help(opt_parser)
  stop("Error: Expression data file must be specified (-i/--input)", call. = FALSE)
}

# Validate format option
valid_formats <- c("Normalize", "Counts")
if (!opts$format %in% valid_formats) {
  stop(sprintf("Error: Invalid format '%s'. Must be one of: %s",
               opts$format, paste(valid_formats, collapse = ", ")), 
       call. = FALSE)
}

# Print run parameters
cat("\n=== VirPred Analysis Parameters ===\n")
cat("Expression file:", opts$expression, "\n")
cat("Data format:", opts$format, "\n")
cat("Output directory:", opts$output, "\n")
cat("Output prefix:", opts$prefix, "\n\n")

# Read input data with error handling
cat("Reading input data...\n")
tryCatch({
  # Try CSV first, then TSV if that fails
  new_data <- tryCatch(
    {
      read.csv(opts$input, row.names = 1, check.names = FALSE)
    },
    error = function(e) {
      read.delim(opts$input, row.names = 1, check.names = FALSE)
    }
  )
  
  # Validate data structure
  if (nrow(new_data) == 0 || ncol(new_data) == 0) {
    stop("Error: Input data appears to be empty or improperly formatted", call. = FALSE)
  }
  if (is.null(rownames(new_data))) {
    stop("Error: Input data must have row names (gene identifiers)", call. = FALSE)
  }
  
  cat(sprintf("Successfully loaded data with %d genes and %d samples\n", 
              nrow(new_data), ncol(new_data)))
},
error = function(e) {
  stop("Failed to read input file: ", e$message, call. = FALSE)
})

# Run analysis with error handling
options(timeout = 1800) 
cat("\nRunning virulence prediction...\n")
result <- tryCatch({
  virulent_predict(new_data, format = opts$format)
},
error = function(e) {
  stop("Prediction failed: ", e$message, call. = FALSE)
})

# Create output directory if needed
if (!dir.exists(opts$output)) {
  cat(sprintf("Creating output directory: %s\n", opts$output))
  dir.create(opts$output, recursive = TRUE)
}

# Save results
output_file <- file.path(opts$output, 
                         sprintf("%s_%s.csv", 
                                 opts$prefix,
                                 format(Sys.time(), "%Y%m%d")))

cat("\nSaving results to:", output_file, "\n")
tryCatch({
  write.csv(result, file = output_file, row.names = FALSE)
  cat("Analysis completed successfully!\n")
},
error = function(e) {
  stop("Failed to save results: ", e$message, call. = FALSE)
})

# Print completion message
cat("\n=== Analysis Summary ===\n")
cat("Input samples:", nrow(result), "\n")
cat("Virulent predictions:", sum(result$Prediction == "Virulent"), "\n")
cat("Avirulent predictions:", sum(result$Prediction == "Avirulent"), "\n")
cat("Results saved to:", output_file, "\n\n")