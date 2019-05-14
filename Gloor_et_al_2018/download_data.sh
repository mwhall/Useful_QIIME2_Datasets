#!/bin/bash

#Set the project accession
ACCESSION=PRJEB24929

#Put everything in a folder
#mkdir -p sequence_data
cd sequence_data

#Fetch the project file manifest
#curl -sLo MANIFEST.txt "http://www.ebi.ac.uk/ena/data/warehouse/search?query=%22study_accession%3D%22${ACCESSION}%22%22&result=read_run&fields=fastq_ftp,sample_alias,sample_accession&display=report"
#sed -i "s/;/\t/g" MANIFEST.txt

#parallel wget ::: `cut -f 2 MANIFEST.txt | tail -n +2`
#parallel wget ::: `cut -f 3 MANIFEST.txt | tail -n +2`

#Fetch the metadata for each sample
for SAMPLE_ACCESSION in `tail -n +2 MANIFEST.txt | cut -f 6`
do
    #Get the XML report from EBI
    curl -sLo ${SAMPLE_ACCESSION}.txt "https://www.ebi.ac.uk/ena/data/view/${SAMPLE_ACCESSION}&display=xml"

    #If there is no metadata file, write the first line
    if [ ! -f "METADATA.txt" ]
    then
        #Scrape the metadata categories from the XML file, save them as the header
        #Change the fields to grab all the ones you want from the project
       awk 'BEGIN {split("host subject id;plaque phenotype;environment (material);sample id", x, ";"); for (k in x) retainTags[ getline; split($0,x,">"); split(x[2], y, "<"); if (y[1] in retainTags){tags[i] = y[1]; i+=1}} END{print "#SampleID\tebi_run"; for (j=1; j<=i; j++){print "\t" tags[j];}}' ${SAMPLE_ACCESSION}.txt > METADATA.txt
    fi

    #Scrape the metadata values from the XML file, save them as a new row
    awk 'BEGIN{split("host subject id;plaque phenotype;environment (material);sample id", x, ";"); for (k in x) retainTags[x[k]] = ""; ORS=""; OFS=""; i=1} {if ($0~/ENA-RUN/) {getline; split($0, x, ">"); split(x[2], y, "<"); run=y[1];} if ($0~/<SAMPLE_ATTRIBUTE>/) { getline; split($0,x,">"); split(x[2], y, "<"); if (y[1] in retainTags) {getline; split($0,x,">"); split(x[2], z, "<"); retainTags[y[1]] = z[1]; i+=1;}}} END{print "\n"; print run "\t" run; for (k in retainTags) {print "\t" retainTags[k];}}' ${SAMPLE_ACCESSION}.txt >> METADATA.txt
done
mkdir -p import_to_qiime

#Put the data into a QIIME-importable format
cd import_to_qiime
for accession in `cut -f 1 ../METADATA.txt | tail -n +2 | xargs`; do 
    ln -s ../${accession}_1.fastq.gz ${accession}_S0_L001_R1_001.fastq.gz
    ln -s ../${accession}_2.fastq.gz ${accession}_S0_L001_R2_001.fastq.gz 
done
ls -l *.fastq.gz | cut -d " " -f 9 | awk 'BEGIN{ORS=""; print "sample-id,filename,direction\n";} {if ($0~/R1/) {dir="forward"} else {dir="reverse"}; split($0, y, "_"); print y[1] "," $0 "," dir "\n";}' > MANIFEST
	echo "{'phred-offset': 33}" > metadata.yml
