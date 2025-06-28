#' Perform Gene Set Variation Analysis (GSVA) on Expression Data
#'
#' This function performs Gene Set Variation Analysis (GSVA) using gene sets from
#' MSigDB's Gene Ontology Biological Process (GO:BP) collection.
#'
#' @param dat A matrix or data frame of expression data with genes as rows and
#'            samples as columns. Row names should be gene symbols.
#' @param format Input data type: "Normalize" for normalized data (default),
#'               "Counts" for RNA-seq count data.
#' @return Matrix of GSVA enrichment scores (gene sets x samples)
#' @export
#'
preProcess_data <- function(dat, format = "Normalize") {
  options(
    msigdbr.base_url = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor/packages/release/data/annotation"
  )
  options(timeout = 1800)
  # Input validation
  if (missing(dat)) stop("Missing required argument: dat")
  if (!inherits(dat, "matrix")) {
    if (inherits(dat, "data.frame")) {
      dat <- as.matrix(dat)
    } else {
      stop("dat must be a matrix or data.frame")
    }
  }
  
  # Load packages
  required_pkgs <- c("GSVA", "dplyr", "msigdbr")
  missing_pkgs <- setdiff(required_pkgs, rownames(installed.packages()))
  if (length(missing_pkgs) > 0) {
    stop("Missing required packages: ", paste(missing_pkgs, collapse = ", "))
  }
  suppressPackageStartupMessages({
    library(GSVA, quietly = TRUE)
    library(dplyr, quietly = TRUE)
    library(msigdbr, quietly = TRUE)
    library(foreach)
    library(doParallel)
  })
  
  # Download GO:BP gene sets 
  tryCatch({
    cl <- makeCluster(detectCores() - 1)
    registerDoParallel(cl)
    go_gene_set <- msigdbr(species = "Homo sapiens",
                           collection = "C5",
                           subcollection = "GO:BP")
    if (nrow(go_gene_set) == 0) stop("Failed to retrieve gene sets")
    go_list <- split(go_gene_set$gene_symbol, go_gene_set$gs_id)
    stopCluster(cl)
    if (length(go_list) == 0) stop("Gene set list creation failed")
  }, error = function(e) {
    stop("Gene set preparation failed: ", e$message)
  })
  
  # Validate format 
  valid_formats <- c("Normalize", "Counts")
  if (!format %in% valid_formats) {
    stop("Invalid format: '", format, "'. Must be one of: ",
         paste(valid_formats, collapse = ", "))
  }
  
  # Run GSVA with parallelization 
  tryCatch({
    kcdf <- if (format == "Normalize") "Gaussian" else "Poisson"
    
    go_param <- gsvaParam(
      exprData = dat,
      geneSets = go_list,
      kcdf = kcdf,
      minSize = 10
    ) 
    
    suppressWarnings({
      go_gsva <- gsva(go_param)
    })
    #go_gsva <- gsva(go_param)
    return(go_gsva)
  }, error = function(e) {
    stop("GSVA analysis failed: ", e$message)
  })
}

#' Train an SVM Model with Radial Basis Kernel
#'
#' @param train_data Training data with features and 'Label' column
#' @param tune Whether to perform hyperparameter tuning (default: FALSE)
#' @return Trained caret model object
#' @export
#'
train_svm_model <- function(train_data, tune = FALSE) {
  # Input validation
  if (missing(train_data)) stop("Missing required argument: train_data")
  if (!"Label" %in% colnames(train_data)) {
    stop("train_data must contain a 'Label' column")
  }
  
  # Load packages 
  required_pkgs <- c("caret", "doParallel")  
  missing_pkgs <- setdiff(required_pkgs, rownames(installed.packages()))
  if (length(missing_pkgs) > 0) {
    stop("Missing required packages: ", paste(missing_pkgs, collapse = ", "))
  }
  suppressPackageStartupMessages({
    library(caret, quietly = TRUE)
    library(doParallel, quietly = TRUE)  
  })
  
  # Prepare data
  train_data$Label <- as.factor(train_data$Label)
  levels(train_data$Label) <- make.names(levels(train_data$Label))
  
  # Training with parallel backend
  tryCatch({
    # 启动并行集群
    cl <- makeCluster(detectCores() - 1)
    registerDoParallel(cl)
    
    if (tune) {
      message("Performing parameter tuning with 5-fold CV (parallel)...")
      tune_grid <- expand.grid(sigma = seq(0, 1, by = 0.01),
                               C = seq(0, 10, by = 0.1))
      cv <- trainControl(
        method = "cv",
        number = 5,
        classProbs = TRUE,
        summaryFunction = multiClassSummary,
        allowParallel = TRUE  
      )
    } else {
      tune_grid <- expand.grid(sigma = 0.34, C = 0.2)
      cv <- trainControl(method = "none", classProbs = TRUE)
    }
    
    model <- caret::train(
      Label ~ .,
      data = train_data,
      method = "svmRadial",
      tuneGrid = tune_grid,
      trControl = cv,
      preProcess = c("center", "scale")
    )
    
    stopCluster(cl)  
    return(model)
  }, error = function(e) {
    if (exists("cl")) stopCluster(cl)
    stop("Model training failed: ", e$message)
  })
}

#' Predict virulence using a trained SVM model
#'
#' @param new_data Expression data (features as rows, samples as columns)
#' @param format Preprocessing method (default: "Normalize")
#' @return Data frame with predictions
#' @export
#'
virulent_predict <- function(new_data, format = "Normalize") {
  # Input validation 
  if (missing(new_data)) stop("Missing required argument: new_data")
  if (!inherits(new_data, c("matrix", "data.frame"))) {
    stop("new_data must be a matrix or data.frame")
  }
  if (nrow(new_data) == 0 || ncol(new_data) == 0) {
    stop("new_data is empty")
  }
  
  # Load training data 
  tryCatch({
    train_data_path <- system.file("data", "train_data.rds", package = "VirPred")
    if (!file.exists(train_data_path)) {
      stop("Training data not found at: ", train_data_path)
    }
    train_data <- readRDS(train_data_path)
  }, error = function(e) {
    stop("Failed to load training data: ", e$message)
  })
  
  # Validate training data 
  if (!"Label" %in% colnames(train_data)) {
    stop("Training data must contain 'Label' column")
  }
  required_sigs <- setdiff(colnames(train_data), "Label")
  if (length(required_sigs) == 0) {
    stop("No features found in training data")
  }
  
  # Preprocess new data 
  tryCatch({
    new_data_gsva <- preProcess_data(new_data, format)
  }, error = function(e) {
    stop("Data preprocessing failed: ", e$message)
  })
  
  # Feature matching 
  available_sigs <- intersect(required_sigs, rownames(new_data_gsva))
  missing_sigs <- setdiff(required_sigs, rownames(new_data_gsva))
  
  if (length(available_sigs) == 0) {
    stop("No matching features found between training data and new data")
  }
  
  # Scenario handling 
  if (length(available_sigs) == length(required_sigs)) {
    message("[SUCCESS] All ", length(required_sigs), " required features detected")
    predict_data <- t(new_data_gsva[required_sigs, ])
    model <- tryCatch({
      train_svm_model(train_data, tune = FALSE)
    }, error = function(e) {
      stop("Model training failed: ", e$message)
    })
  } else if (length(available_sigs) >= 8) {
    warning(
      "[WARNING] Only ", length(available_sigs), "/", length(required_sigs),
      " features available. Prediction reliability reduced.\n",
      "Missing features: ", paste(missing_sigs, collapse = ", ")
    )
    predict_data <- t(new_data_gsva[available_sigs, ])
    train_subset <- train_data[, c(available_sigs, "Label"), drop = FALSE]
    model <- tryCatch({
      train_svm_model(train_subset, tune = TRUE)
    }, error = function(e) {
      stop("Model training with subset failed: ", e$message)
    })
  } else {
    stop(
      "[ERROR] Insufficient features (", length(available_sigs),
      " available, minimum 8 required)\n",
      "Missing features (", length(missing_sigs), "): \n",
      paste(strwrap(paste(missing_sigs, collapse = ", "), width = 60), collapse = "\n")
    )
  }
  
  # Parallel prediction 
  tryCatch({
    library(foreach)
    library(doParallel)
    cl <- makeCluster(detectCores() - 1)
    registerDoParallel(cl)
    
    sample_ids <- colnames(new_data_gsva)
    chunk_size <- ceiling(length(sample_ids) / detectCores())
    chunks <- split(sample_ids, ceiling(seq_along(sample_ids) / chunk_size))
    
    results <- foreach(chunk = chunks, .combine = rbind, .packages = "caret") %dopar% {
      chunk_data <- t(new_data_gsva[available_sigs, chunk, drop = FALSE])
      y_pred <- predict(model, chunk_data)
      y_pred_prob <- predict(model, chunk_data, type = "prob")[, "X1"]
      
      data.frame(
        SampleID = chunk,
        Prediction = ifelse(y_pred == "X1", "Virulent", "Avirulent"),
        Probability = y_pred_prob,
        stringsAsFactors = FALSE
      )
    }
    
    stopCluster(cl)
    return(results)
  }, error = function(e) {
    if (exists("cl")) stopCluster(cl)
    stop("Prediction failed: ", e$message)
  })
}
