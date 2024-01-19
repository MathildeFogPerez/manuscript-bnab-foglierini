#!/bin/bash

WORKINGDIR=$1
DONOR=$2
SAMPLE=$3
DBSPECIES="human"
IGBLASTPATH="/home/localadmin/TOOLS/ncbi-igblast-1.17.1/"
DBNAME="imgt_db_human_15_12_21" 
SCRIPTSFOLDER="PATH_TO/jar_files"
CELLRANGEROUTDIR="PATH_TO/cellranger_out/"

set -e

FOLDER=$WORKINGDIR/$SAMPLE
DBPATH=$IGBLASTPATH/database/$DBNAME

mkdir -p $FOLDER

cp $CELLRANGEROUTDIR/"$SAMPLE"_VDJ/outs/filtered_contig_annotations.csv $FOLDER
cp $CELLRANGEROUTDIR/"$SAMPLE"_VDJ/outs/filtered_contig.fasta $FOLDER

cd $IGBLASTPATH
$IGBLASTPATH/bin/igblastn -num_threads 50 -germline_db_V $DBPATH/"$DBSPECIES"_ig_V -germline_db_D $DBPATH/"$DBSPECIES"_ig_D  -germline_db_J $DBPATH/"$DBSPECIES"_ig_J -auxiliary_data optional_file/human_gl.aux  -ig_seqtype Ig -organism human  -outfmt '7 std qseq sseq btop'  -query $FOLDER/filtered_contig.fasta  -out $FOLDER/"$SAMPLE"_filtered_contig_igblast.fmt7

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "IgBlast ended, MakeDb $dt"
cd $FOLDER
MakeDb.py igblast -i "$SAMPLE"_filtered_contig_igblast.fmt7 -s filtered_contig.fasta -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta --10x filtered_contig_annotations.csv --extended

#Keep only the productive sequences
ParseDb.py select -d "$SAMPLE"_filtered_contig_igblast_db-pass.tsv -f productive -u T

#split the file in 2
ParseDb.py select -d "$SAMPLE"_filtered_contig_igblast_db-pass_parse-select.tsv -f locus -u "IGH" --logic all --regex --outname heavy
ParseDb.py select -d "$SAMPLE"_filtered_contig_igblast_db-pass_parse-select.tsv -f locus -u "IG[LK]" --logic all --regex --outname light

#Add the sample name to the sequence_id
echo "Add sample name to sequence ids"
TOADD=$SAMPLE"_"
head -1 heavy_parse-select.tsv > heavyline
head -1 light_parse-select.tsv >lightline
tail -n +2 heavy_parse-select.tsv >heavy_parse-select_TOMODIF.tsv
tail -n +2 light_parse-select.tsv >light_parse-select_TOMODIF.tsv
sed -e "s/^/$TOADD/" heavy_parse-select_TOMODIF.tsv > heavy_parse-select_i.tsv
sed -e "s/^/$TOADD/" light_parse-select_TOMODIF.tsv  > light_parse-select_i.tsv

cat heavyline heavy_parse-select_i.tsv > heavy_parse-select.tsv
cat lightline light_parse-select_i.tsv >light_parse-select.tsv

heavySequences=$(cat heavy_parse-select.tsv | wc -l )
heavySeq="$((heavySequences-1))"
echo "Number of heavy sequences after concatenation $heavySeq"

#make the clustering for heavy chain
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Heavy chain clustering"
DefineClones.py -d heavy_parse-select.tsv --act set --model ham --norm len --dist 0.15 

heavySequences=$(cat heavy_parse-select_clone-pass.tsv | wc -l )

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Light chain checking..."
light_cluster.py -d heavy_parse-select_clone-pass.tsv -e light_parse-select.tsv -o cleaned_heavy_parse-select_clone-pass.tsv

newheavySequences=$(cat cleaned_heavy_parse-select_clone-pass.tsv | wc -l )
newheavySeq="$((newheavySequences-1))"
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Number of heavy sequences after checking light chain $newheavySeq"
removed=$(($heavySequences - $newheavySequences))
echo "$dt- **** Number of REMOVED heavy sequences after checking light chain of ALL run $removed ****"

#create the germlines
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Create germline heavy chain"
CreateGermlines.py -d cleaned_heavy_parse-select_clone-pass.tsv --cloned -g dmask -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta 

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Create germline light chain"
CreateGermlines.py -d light_parse-select.tsv -g dmask -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta 

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Create final AIRR file"
#The makeSequenceIds option will use metadata.txt file and create for each sequence an unique ID like the following: 
#M-231-K-H-A0-1102-A-1 -> M = memory, 231=id (not unique for 10X data), K= kappa, H=related heavy mate, A0= experiment id, 1102=collection date (2011 02), A= donor (D1), 1=duplicate count

java -Xmx12288m -jar $SCRIPTSFOLDER/CreateAIRRtsvFile.jar cleaned_heavy_parse-select_clone-pass_germ-pass.tsv light_parse-select_germ-pass.tsv AIRR_file_"$SAMPLE".tsv makeSequenceIds

