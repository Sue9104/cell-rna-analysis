input=$1
prefix=$2

genome=/public/home/msu/genomes/hg38/ensembl/Homo_sapiens.GRCh38.dna_sm.primary_assembly.chr.fa
gtf=/public/home/msu/genomes/hg38/gencode/gencode.v42.primary_assembly.annotation.gtf
cage=/public/home/msu/pipelines/exon-usages-in-3rd-seq/SQANTI3/data/ref_TSS_annotation/human.refTSS_v3.1.hg38.bed
polya=/public/home/msu/pipelines/exon-usages-in-3rd-seq/SQANTI3/data/polyA_motifs/mouse_and_human.polyA_motif.txt
primers=/public/home/msu/projects/seq3/examples/primers.fasta
barcodes=/public/home/msu/projects/seq3/examples/3M-february-2018-REVERSE-COMPLEMENTED.txt.gz
# cDNA primer removal and read orientation
echo lima --per-read --isoseq ${input} ${primers} ${prefix}.output.bam
[ ! -f "${prefix}.output.5p--3p.bam" ] && lima --per-read --isoseq ${input} ${primers} ${prefix}.output.bam

# Clip UMI and cell barcode
echo isoseq3 tag ${prefix}.output.5p--3p.bam ${prefix}.flt.bam --design T-12U-16B
[ ! -f "${prefix}.flt.bam" ] && isoseq3 tag ${prefix}.output.5p--3p.bam ${prefix}.flt.bam --design T-12U-16B

# Remove poly(A) tails and concatemer
echo isoseq3 refine ${prefix}.flt.bam ${primers} ${prefix}.fltnc.bam --require-polya
[ ! -f "${prefix}.fltnc.bam" ] && isoseq3 refine ${prefix}.flt.bam ${primers} ${prefix}.fltnc.bam --require-polya

# Correct single cell barcodes based on an include list
echo isoseq3 correct -B ${barcodes} ${prefix}.fltnc.bam ${prefix}.corrected.bam
[ ! -f "${prefix}.corrected.bam" ] && isoseq3 correct -B ${barcodes} ${prefix}.fltnc.bam ${prefix}.corrected.bam
## Barcode Statistics Documentation
###isoseq3 bcstats --json ${prefix}.sample.bcstats.json -o ${prefix}.sample.bcstats.tsv ${prefix}.corrected.bam

# Deduplicate reads based on UMIs
echo samtools sort -@ 40 -t CB ${prefix}.corrected.bam -o ${prefix}.corrected.sorted.bam
[ ! -f "${prefix}.corrected.sorted.bam" ] && samtools sort -@ 40 -t CB ${prefix}.corrected.bam -o ${prefix}.corrected.sorted.bam
echo isoseq3 groupdedup ${prefix}.corrected.sorted.bam ${prefix}.dedup.bam
[ ! -f "${prefix}.dedup.bam" ] && isoseq3 groupdedup ${prefix}.corrected.sorted.bam ${prefix}.dedup.bam

# Map reads to a reference genom
echo pbmm2 align --preset ISOSEQ --sort ${prefix}.dedup.bam ${genome} ${prefix}.aligned.bam
[ ! -f "${prefix}.aligned.bam" ] && pbmm2 align --preset ISOSEQ --sort ${prefix}.dedup.bam ${genome} ${prefix}.aligned.bam

# Collapse into unique isoforms
## Single-cell IsoSeq
echo isoseq3 collapse ${prefix}.aligned.bam ${prefix}.collapse.gff
[ ! -f "${prefix}.collapse.gff" ] && isoseq3 collapse ${prefix}.aligned.bam ${prefix}.collapse.gff
## Bulk IsoSeq
#isoseq3 collapse --do-not-collapse-extra-5exons mapped.bam collapsed.gff

# Sort input transcript GFF
echo pigeon sort ${prefix}.collapse.gff -o ${prefix}.sorted.gff
[ ! -f "${prefix}.sorted.gff" ] && pigeon sort ${prefix}.collapse.gff -o ${prefix}.sorted.gff

# Index the reference files
#pigeon index gencode.annotation.gtf
#pigeon index cage.bed
#pigeon index intropolis.tsv

# Classify Isoforms
#pigeon classify sorted.gff annotations.gtf reference.fa
echo pigeon classify ${prefix}.sorted.gff ${gtf} ${genome} --fl ${prefix}.collapse.abundance.txt --cage-peak ${cage} --poly-a ${polya} -o ${prefix}
[ ! -f "${prefix}_classification.txt" ] && pigeon classify ${prefix}.sorted.gff ${gtf} ${genome} --fl ${prefix}.collapse.abundance.txt --cage-peak ${cage} --poly-a ${polya} -o ${prefix}

# Filter isoforms
echo pigeon filter ${prefix}_classification.txt --isoforms ${prefix}.sorted.gff
[ ! -f "${prefix}_classification.filtered_lite_classification.txt" ] && pigeon filter ${prefix}_classification.txt --isoforms ${prefix}.sorted.gff

# Report gene saturation
echo pigeon report ${prefix}_classification.filtered_lite_classification.txt ${prefix}.saturation.txt
[ ! -f "${prefix}.saturation.txt" ] && pigeon report ${prefix}_classification.filtered_lite_classification.txt ${prefix}.saturation.txt


# Make Seurat compatible input
echo pigeon make-seurat --dedup ${prefix}.dedup.fasta --group ${prefix}.collapse.group.txt -o ${prefix} ${prefix}_classification.filtered_lite_classification.txt
pigeon make-seurat --dedup ${prefix}.dedup.fasta --group ${prefix}.collapse.group.txt -o ${prefix} ${prefix}_classification.filtered_lite_classification.txt
