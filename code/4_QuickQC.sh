#!/bin/bash

## Jillian Haney, 05/21/2015
## Script to merge STAR output from multiple lanes (obtained in Stage 1 of the pipeline), collect QC information, mark duplicates,
## and remove reads that mapped to different chromosomes to produce final .bam file to be used in the last stage of the pipeline.
## This script should be fed into 3_MassQSUB2.sh
## Most QC is derived from Neel Parikshak's script, RunPicardScripts.sh

##Define Input Variables and Functions

PROCESSDIR=$1 	## ~/data/R100	<- workingdir AND bamdir - so [${workingdir}/${bfile}/ = $PROCESSDIR/] here
DIRNAME=$2	## R100			<- bfile, -.bam at end
PARENTDIR=$3	## ~/data

FASTA=/geschwindlabshares/CrossDisorder_transcriptome_comparison/1_RNAseq/refGen/genome.fa
JAV=/usr/java/jdk1.7.0_51/bin
PIC=/geschwindlabshares/CrossDisorder_transcriptome_comparison/1_RNAseq/bin/picard-master/dist/picard.jar
REFFLAT=/geschwindlabshares/CrossDisorder_transcriptome_comparison/1_RNAseq/refGen/refFlat.v75.txt	## Created from ensembl v75 GTF using 
													## ./gtfToGenePred -genePredExt -geneNameAsName2

## Merge

echo "Script has begun..."

cd $PARENTDIR

lanes=$( ls -d ${DIRNAME}* | wc -l )
echo "Sample Lanes to copy or merge: $(($lanes - 1))"
single=2

cd $PROCESSDIR

if [ ! -f ${DIRNAME}_raw.bam ] && [ "$lanes" -gt "$single" ]; then

samtools merge -f ${DIRNAME}_raw.bam ${PARENTDIR}/${DIRNAME}-*_L00*/tophat_raw/accepted_hits.bam

echo "${DIRNAME}_raw merging is complete"

elif [ ! -f ${DIRNAME}_raw.bam ] && [ "$lanes" -eq "$single" ]; then

cp ${PARENTDIR}/${DIRNAME}_*_L00*/Aligned.out.bam ${DIRNAME}_raw.bam

echo "${DIRNAME}_raw copying is complete"

else

echo "Copying or merging already complete"

fi


## QC on Bamfiles using Picard Tools and RSeqQC

if [ ! -f ${PROCESSDIR}/PEmatched_markdup_sorted.bai  ]; then 
	## Execute scripts if either QC output file is not present
    
	echo "Running QC stats scripts from PicardTools..."
        mkdir -p tmp
    	mkdir -p tmp2

    if [ ! -f ${PROCESSDIR}/sorted_reads.bai  ]; then
        ${JAV}/java -Xmx4g -Djava.io.tmpdir=${PROCESSDIR}/tmp -jar ${PIC} SortSam INPUT=${DIRNAME}_raw.bam OUTPUT=${PROCESSDIR}/sorted_reads.bam SORT_ORDER=coordinate TMP_DIR=${PROCESSDIR}/tmp
        ## Reorder the .bam file according to the reference at hand
	echo "sorted_reads.bam is now created"	

	 ${JAV}/java -Xmx2g -jar ${PIC} BuildBamIndex INPUT=${PROCESSDIR}/sorted_reads.bam
        ## Index the sorted reads file
        echo "sorted reads file is now indexed"

    else
        echo ".bam file already sorted"
    fi

##    if [ ! -f ${PROCESSDIR}/reordered_reads.bam  ]; then
##	${JAV}/java -Xmx4g -Djava.io.tmpdir=${PROCESSDIR}/tmp -jar ${PIC} ReorderSam INPUT=${PROCESSDIR}/sorted_reads.bam OUTPUT=${PROCESSDIR}/reordered_reads.bam REFERENCE=${FASTA} TMP_DIR=${PROCESSDIR}/tmp 
	## Reorder the .bam file according to the reference at hand
##	echo "reordered_reads.bam is now created"

##    else
##	echo ".bam file already reordered"
##    fi
    
    
##    if [ ! -f ${PROCESSDIR}/PEmatched_markdup_sorted.bai ]; then
##	${JAV}/java -Xmx4g -Djava.io.tmpdir=${PROCESSDIR}/tmp -jar ${PIC} MarkDuplicates INPUT=${PROCESSDIR}/reordered_reads.bam METRICS_FILE=${PROCESSDIR}/duplication_stats.txt ASSUME_SORTED=false OUTPUT=${PROCESSDIR}/reordered_duplication_marked_reads.bam REMOVE_DUPLICATES=FALSE TMP_DIR=${PROCESSDIR}/tmp
	## Collect read duplication metrics if the file is not present, output the marked duplicates file AND keep duplicates for future expression analysis
##	echo "duplicates are now marked"	

##	samtools view -h -f 0x0002 -b reordered_duplication_marked_reads.bam > PEmatched_markdup.bam     ##keep only reads where paired ends map properly together
##	echo "all reads left are now only proper pairs"

##	${JAV}/java -Xmx4g -Djava.io.tmpdir=${PROCESSDIR}/tmp2 -jar ${PIC} SortSam INPUT=${PROCESSDIR}/PEmatched_markdup.bam OUTPUT=${PROCESSDIR}/PEmatched_markdup_sorted.bam SORT_ORDER=coordinate TMP_DIR=${PROCESSDIR}/tmp2
	## Sort the marked-duplicates file
##	echo "marked-duplicates file is now sorted"	

##	${JAV}/java -Xmx2g -jar ${PIC} BuildBamIndex INPUT=${PROCESSDIR}/PEmatched_markdup_sorted.bam
	## Index the marked-duplicates file
##	echo "marked-duplicates file is now indexed"	

 ##   else
##	echo ".bam file already analyzed for duplicates and processed for deduplication"
##    fi
    
else
    echo "RNA seq QC metric files already present" 
fi


##if [ -f ${PROCESSDIR}/PEmatched_markdup_sorted.bai ]; then
 ##       echo "cleaning up the extra .bam files"
##	rm ${PROCESSDIR}/reordered_reads.bam ## Save space... if QC outputs are present, delete the .bam files
##	rm ${PROCESSDIR}/sorted_reads.bai
 ##       rm ${PROCESSDIR}/sorted_reads.bam
##	rm ${PROCESSDIR}/PEmatched_markdup.bam
##	rm ${PROCESSDIR}/reordered_duplication_marked_reads.bam
##        rm -rf ${PARENTDIR}/${DIRNAME}_*_L00*
##fi

echo "Script Complete!"
