


> Written with [StackEdit](https://stackedit.io/).
> **

## VirPred:Influenza Virus Pathogenicity Prediction Toolkit

**  
VirPred is a machine learning-based tool for predicting influenza virus pathogenicity using host transcriptomic profiles. The tool accepts both RNA-Seq data (raw counts or normalized expressions including log2TPM, log2FPKM, log2RPKM, logCPM...) and microarray data (log-transformed normalized expressions).

**Install VirPred**

    # Create new conda env and install R
    conda create -n VirPred -c conda-forge r-base=4.4
    # Activate env
    conda activate VirPred
    # Install GSVA
    conda install bioconda::bioconductor-gsva
    # Download and install VirPred
    wget https://github.com/xinglianWang/VirPred/archive/refs/heads/main.zip
    unzip main.zip
    cd VirPred-main
    make install
    source ~/.bashrc

**Parameter Function**
|-i/--input  | input file; path to expression data file(csv) with genes as  rows and samples as columns
|
|-f /--format|{Normalize/Counts}, data format type, default:Normalize. For RNA-Seq raw Counts ,use -f  Counts ; or Normalized data,such as log2TPM/FPKM/RPKM,logCPM, or log-transformed normalized microarray data, use default parameter|
| -o/--output | Output directory path (default:current directory) |
|-p/--prefix|Output file prefix (default : "VirPred_results")|

**Example**

    # Normalized data
    VirPred -i path/new_data.csv -o path/results/ # path: Input/output data storage directory
    # RNA-Seq raw Counts
    VirPred -i path/new_data.csv -f Counts -o path/results/







 

 

