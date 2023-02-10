basedir=$(dirname "$0")
in_gff=$1
in_abundance=$2
in_group=$3
in_dedup_fa=$4
outdir=$5
prefix=$6

genome=/public/home/msu/genomes/hg38/ensembl/Homo_sapiens.GRCh38.dna_sm.primary_assembly.chr.fa
gtf=/public/home/msu/genomes/hg38/gencode/gencode.v42.primary_assembly.annotation.gtf
cage=/public/home/msu/pipelines/exon-usages-in-3rd-seq/SQANTI3/data/ref_TSS_annotation/human.refTSS_v3.1.hg38.bed
polya=/public/home/msu/pipelines/exon-usages-in-3rd-seq/SQANTI3/data/polyA_motifs/mouse_and_human.polyA_motif.txt
primers=/public/home/msu/projects/seq3/examples/primers.fasta
barcodes=/public/home/msu/projects/seq3/examples/3M-february-2018-REVERSE-COMPLEMENTED.txt.gz
python3=/public/home/msu/miniconda3/bin/python3
# create outdir if not exists
[ ! -d "${outdir}" ] && mkdir ${outdir}


# Sort input transcript GFF
echo pigeon sort ${in_gff} -o ${outdir}/${prefix}.sorted.gff
[ ! -f "${outdir}/${prefix}.sorted.gff" ] && pigeon sort ${in_gff} -o ${outdir}/${prefix}.sorted.gff

# Index the reference files
#pigeon index gencode.annotation.gtf
#pigeon index cage.bed
#pigeon index intropolis.tsv

# Classify Isoforms
#pigeon classify sorted.gff annotations.gtf reference.fa
echo pigeon classify ${outdir}/${prefix}.sorted.gff ${gtf} ${genome} --fl ${in_abundance} --cage-peak ${cage} --poly-a ${polya} -d ${outdir} -o ${prefix}
[ ! -f "${outdir}/${prefix}_classification.txt" ] && pigeon classify ${outdir}/${prefix}.sorted.gff ${gtf} ${genome} --fl ${in_abundance} --cage-peak ${cage} --poly-a ${polya} -d ${outdir} -o ${prefix}

# Filter isoforms
echo pigeon filter ${outdir}/${prefix}_classification.txt --isoforms ${outdir}/${prefix}.sorted.gff
[ ! -f "${outdir}/${prefix}_classification.filtered_lite_classification.txt" ] && pigeon filter ${outdir}/${prefix}_classification.txt --isoforms ${outdir}/${prefix}.sorted.gff

# Report gene saturation
echo pigeon report ${outdir}/${prefix}_classification.filtered_lite_classification.txt ${outdir}/${prefix}.saturation.txt
[ ! -f "${outdir}/${prefix}.saturation.txt" ] && pigeon report ${outdir}/${prefix}_classification.filtered_lite_classification.txt ${outdir}/${prefix}.saturation.txt


# Make Seurat compatible input
echo pigeon make-seurat --dedup ${in_dedup_fa} --group ${in_group} -d ${outdir} -o ${prefix} ${outdir}/${prefix}_classification.filtered_lite_classification.txt
pigeon make-seurat --dedup ${in_dedup_fa} --group ${in_group} -d ${outdir} -o ${prefix} ${outdir}/${prefix}_classification.filtered_lite_classification.txt
