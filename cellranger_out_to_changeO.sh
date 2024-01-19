#!/bin/bash

WORKINGDIR=$1
SAMPLE=$2
DBSPECIES="human"
IGBLASTPATH="/home/localadmin/TOOLS/ncbi-igblast-1.17.1/"
DBNAME="imgt_db_human_15_12_21" 

set -e

FOLDER=$WORKINGDIR/$SAMPLE
DBPATH=$IGBLASTPATH/database/$DBNAME

mkdir -p $FOLDER

cd $IGBLASTPATH
$IGBLASTPATH/bin/igblastn -num_threads 50 -germline_db_V $DBPATH/"$DBSPECIES"_ig_V -germline_db_D $DBPATH/"$DBSPECIES"_ig_D  -germline_db_J $DBPATH/"$DBSPECIES"_ig_J -auxiliary_data optional_file/human_gl.aux  -ig_seqtype Ig -organism human  -outfmt '7 std qseq sseq btop'  -query $FOLDER/filtered_contig.fasta  -out $FOLDER/"$SAMPLE"_filtered_contig_igblast.fmt7

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "IgBlast ended, MakeDb $dt"
cd $FOLDER
MakeDb.py igblast -i "$SAMPLE"_filtered_contig_igblast.fmt7 -s filtered_contig.fasta -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta --10x filtered_contig_annotations.csv --extended

#Keep only the productive sequences
ParseDb.py select -d "$SAMPLE"_filtered_contig_igblast_db-pass.tsv -f productive -u T