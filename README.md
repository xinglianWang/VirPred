
## VirPred:Influenza Virus Pathogenicity Prediction Toolkit

VirPred is a machine learning-based tool for predicting influenza virus pathogenicity using host transcriptomic profiles. The tool accepts both RNA-Seq data (raw counts or normalized expressions including log2TPM, log2FPKM, log2RPKM, logCPM...) and microarray data (log-transformed normalized expressions).

**Install VirPred**

    # Step1: Download VirPred from GitHub using Git
    git clone https://github.com/xinglianWang/VirPred.git
    # Step2: Create a new conda environment and install R
    conda create -n VirPred -c conda-forge r-base=4.4
    conda activate VirPred
    # Step 3: Install required R packages and set up VirPred
    conda install bioconda::bioconductor-gsva 
    make -C ./VirPred install
    source ~/.bashrc

**Parameter Function**

 - -i/--input: 
 input file; path to expression data file(csv) with genes as  rows and samples as columns
 - -f /--format:
 Specifies input data mode (default: `Normalize`). For RNA-Seq raw count data (e.g., from featureCounts/HTSeq), explicitly use `-f Counts` . For normalized data (log2TPM/FPKM/RPKM for RNA-Seq or log-transformed microarray data), use the default `Normalize` mode .
 - -o/--output:
 Output directory path (default:current directory)
 - -p/--prefix:
 Output file prefix (default : "VirPred_results")

**Example**

    # Normalized data
    VirPred -i path/new_data.csv -o path/results/ # path: Input/output data storage directory
    # RNA-Seq raw Counts
    VirPred -i path/new_data.csv -f Counts -o path/results/







 

 

