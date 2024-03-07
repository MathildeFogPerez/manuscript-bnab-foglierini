# manuscript-bnab-foglierini

Rapid Automatic Identification of bNAbs (RAIN) to identify bNAbs from antibody immune repertoire.
Four machine learning models are used to predict Bnabs in the repertoires of HIV-1 immune donors: Anomaly Detection (AD), Decision Tree (DT), Random Forest (RF) and Super Learner (SL).

Copyright (C) 2024  Mathilde Foglierini Perez

email: mathilde.foglierini-perez@chuv.ch

### SUMMARY ###

We have made available here a series of scripts to process scBCR sequencing data coming from HIV-1 immune donors in order to find BnAb in their repertoires. 
The scripts are primarily intended as reference for the manuscript "RAIN: a Machine Learning-based identification of HIV-1 bNAbs".
If you aim to run our pipeline with your own 10X VDJ data, please follow the **PIPELINE short version**.

Raw data of paired BCRs coming from HIV immune donors are available at https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?&acc=GSE229123


### LICENSE ###

This code is distributed open source under the terms of the Apache License, Version 2.0.


### INSTALL ###

#### Paireds BCR repertoires processing 

The following software are required:

a) IgBlast v1.17.1  or download latest version from https://ftp.ncbi.nih.gov/blast/executables/igblast/release/LATEST

b) Change-O v1.2 or latest https://changeo.readthedocs.io/en/stable/install.html#installation 

c) R v4.2 with [tidyverse](https://www.tidyverse.org/) and [seqinr](https://cran.r-project.org/web/packages/seqinr/index.html) packages


Please install [Java JDK 15](https://www.oracle.com/java/technologies/javase/jdk15-archive-downloads.html), instead of R, if you want to run the **long version** of the pipeline. As previously described [here](https://github.com/MathildeFogPerez/manuscript-rep-phad/tree/main), we developed a pipeline to generate a customized table of paired BCRs in AIRR format.


#### Machine learning algorithms

The jupyter notebook can be run after installing Graphitz: https://graphviz.org/download/

Python libraries (using Python 3.8.16):
- scikit-learn v1.0.2
- matplotlib 3.6.2
- scipy 1.8.1
- pandas 1.4.2
- seaborn 0.11.2  
- numpy 1.22.3
- graphviz 0.20
 



<br/><br/>

### PIPELINE short version ### TO USE FOR FUTURE RAIN USERS

1. Create a directory for each experiment and copy the 10X output files in each directory:

        -filtered_contig_annotations.csv
        -filtered_contig.fasta

2. For each experiment, launch the bash script (**change-O from Immcantation workflow**) that will result into a $SAMPLE_igblast_db-pass_parse-select.tsv file

        cellranger_out_to_changeO.sh /MY_WORKING_DIR/ G4 >out_pipeline_G4.txt


3. For each experiment, run the R script **RAIN_feature_converter.rmd** to create a file with our features of interest $SAMPLE_featuresTable.tsv. 
   The file contains changeO clonotype characteristics (one row = 1VH+1VK/L) and the features used by the ML algorithms. 


4. Launch the jupyter notebooks by setting the experiment name and path: **IMPORTANT** run first the AnomalyDetection_PUB.ipynb and then the DecisionTree_RandomForest_PUB.ipynb
   
5. The SuperLearner_PUB.ipynb can be run to confirm the prediction (by AD, DT and RF) of the BnAbs of the HIV+ infected donors

The execution of the jupyter notebooks generate different figures and files:
 * creation of an 'output' folder with related files for the training and validation models for each antigenic site
 * a predicted bnabs tsv file (changeO heavy and light characteristics + features columns) for each experiment and each antigenic site

 <br/><br/>

 ### PIPELINE long version ### FOR PUBLICATION

1. Create a directory for each experiment and create a metadata.txt file in each directory:

        sample cellType newSampleId colDate donor ag
        G4 M G4 2302 P4 none

2. Launch the bash script that will result into a customized paired BCRs table in AIRR format

        cellranger_out_to_AIRRfile.sh /MY_WORKING_DIR/ P4 G4 >out_pipeline_G4.txt


3. Execute the jar file to convert the AIRR file into our features of interest table

        java -jar PrepareFeaturesTableFromAirrFile.jar G4 MY_WORKING_DIR/HIVdonors_AIRR/G4/AIRR_file_G4.tsv

4. Launch the jupyter notebooks by setting the experiment name and path: run first the AnomalyDetection_PUB.ipynb and then the DecisionTree_RandomForest_PUB.ipynb
   
5. The SuperLearner_PUB.ipynb can be run to confirm the prediction (by AD, DT and RF) of the BnAbs of the HIV+ infected donors

The execution of the jupyter notebooks generate the different figures and files used for the publication:
 * creation of an 'output' folder with related files for the training and validation models for each antigenic site
 * a predicted bnabs file in AIRR format (+ features columns) for each experiment and each antigenic site

   
<br/><br/>


#### Notes:
  
* **PIPELINE short version**: The 'HIVdonors_FILES' folder contains the cellranger output file, the changeO _igblast_db-pass_parse-select.tsv file and the featuresTable.tsv file generated by the R script.
* **PIPELINE long version**: All the files generated by the Java script PrepareFeaturesTableFromAirrFile.jar can be found in each subfolder of the 'HIVdonors_AIRR' folder, along with their related AIRR file.
* A java script is also available for the conversion of VDJ_Dominant_Contigs.csv BD Rhapsody file to cellranger-like output files (filtered_contig_annotations.csv and filtered_contig.fasta).

 


