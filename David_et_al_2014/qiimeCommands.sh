#!/bin/bash

SERIES="SalivaA"

cd sequence_data/${SERIES}/
#This command imports the FASTQ files into a QIIME artifact
#qiime tools import --type 'SampleData[SequencesWithQuality]' --input-path import_to_qiime --output-path reads

#Using DADA2 to analyze quality scores of 10 random samples
#qiime demux summarize --p-n 10000 --i-data reads.qza --o-visualization qual_viz

#Denoising with DADA2. Using quality score visualizations, you can choose trunc-len-f and trunc-len-r (note: sequences < trunc-len in length are discarded!)
#qiime dada2 denoise-single --i-demultiplexed-seqs reads.qza --o-table unfiltered_table --o-representative-sequences representative_sequences --p-trunc-len 100 --p-trim-left 12 --p-n-threads 4 --o-denoising-stats denoise_stats.qza --verbose

wget https://data.qiime2.org/2019.1/common/gg-13-8-99-nb-classifier.qza
#If you have a large amount of RAM (32GB or greater), try the larger SILVA database:
#wget https://data.qiime2.org/2019.1/common/silva-132-99-nb-classifier.qza

qiime feature-classifier classify-sklearn --i-classifier gg-13-8-99-nb-classifier.qza --i-reads representative_sequences.qza --o-classification taxonomy

#This visualization shows us the sequences/sample spread
qiime feature-table summarize --i-table unfiltered_table.qza --o-visualization table_summary

#qiime feature-table filter-samples --i-table unfiltered_table.qza --o-filtered-table table.qza --p-min-frequency 10000
#Taxa bar plots
qiime taxa barplot --i-table table.qza --i-taxonomy taxonomy.qza --m-metadata-file METADATA.txt --o-visualization taxa-bar-plots

#Steps for generating a phylogenetic tree
#qiime alignment mafft --i-sequences representative_sequences.qza --o-alignment aligned_representative_sequences

#qiime alignment mask --i-alignment aligned_representative_sequences.qza --o-masked-alignment masked_aligned_representative_sequences

#qiime phylogeny fasttree --i-alignment masked_aligned_representative_sequences.qza --o-tree unrooted_tree

#qiime phylogeny midpoint-root --i-tree unrooted_tree.qza --o-rooted-tree rooted_tree

#Generate alpha/beta diversity measures at 10000 sequences/sample
#Also generates PCoA plots automatically
#qiime diversity core-metrics-phylogenetic --i-phylogeny rooted_tree.qza --i-table table.qza --p-sampling-depth 10000 --output-dir diversity_10000 --m-metadata-file METADATA.txt

#Test for between-group differences
#qiime diversity alpha-group-significance --i-alpha-diversity diversity_10000/faith_pd_vector.qza --m-metadata-file METADATA.txt --o-visualization diversity_10000/alpha_PD_significance

#qiime diversity alpha-group-significance --i-alpha-diversity diversity_10000/shannon_vector.qza --m-metadata-file METADATA.txt --o-visualization diversity_10000/alpha_shannon_significance

#Alpha rarefaction curves show taxon accumulation as a function of sequence depth
#qiime diversity alpha-rarefaction --i-table table.qza --p-max-depth 10000 --o-visualization diversity_10000/alpha_rarefaction.qzv --m-metadata-file METADATA.txt --i-phylogeny rooted_tree.qza
