input=$1
abundance=$2
outdir=$3
prefix=$4

genome=/public/home/msu/genomes/hg38/ensembl/Homo_sapiens.GRCh38.dna_sm.primary_assembly.chr.fa
gtf=/public/home/msu/genomes/hg38/gencode/gencode.v42.primary_assembly.annotation.gtf
cage=/public/home/msu/pipelines/exon-usages-in-3rd-seq/SQANTI3/data/ref_TSS_annotation/human.refTSS_v3.1.hg38.bed
polya=/public/home/msu/pipelines/exon-usages-in-3rd-seq/SQANTI3/data/polyA_motifs/mouse_and_human.polyA_motif.txt
tappas=/public/home/msu/genomes/hg38/tappas/Homo_sapiens_GRCh38_Ensembl_86.gff3
filter=/public/home/msu/pipelines/exon-usages-in-3rd-seq/SQANTI3/utilities/filter/filter_default.json
cpus=40

# Quality Control using SQANTI3
echo sqanti3_qc.py ${input} ${gtf} ${genome} --CAGE_peak ${cage} --polyA_motif_list ${polya} -fl ${abundance} --isoAnnotLite --gff3 ${tappas} --report both --cpus ${cpus} --dir ${outdir} --output ${prefix}
[ ! -f "${outdir}/${prefix}.gff3" ] && sqanti3_qc.py ${input} ${gtf} ${genome} --CAGE_peak ${cage} --polyA_motif_list ${polya} -fl ${abundance} --isoAnnotLite --gff3 ${tappas} --report both --cpus ${cpus} --dir ${outdir} --output ${prefix}

# Filtering using SQANTI3
echo sqanti3_filter.py rules ${outdir}/${prefix}_classification.txt --isoAnnotGFF3 ${outdir}/${prefix}.gff3 --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}_corrected.gtf --faa ${outdir}/${prefix}_corrected.faa --dir ${outdir} --output ${prefix}.rules
[ ! -f "${outdir}/${prefix}.rules_RulesFilter_result_classification.txt" ] && sqanti3_filter.py rules ${outdir}/${prefix}_classification.txt --isoAnnotGFF3 ${outdir}/${prefix}.gff3 --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}_corrected.gtf --faa ${outdir}/${prefix}_corrected.faa --dir ${outdir} --output ${prefix}.rules
echo sqanti3_filter.py ML ${outdir}/${prefix}_classification.txt    --isoAnnotGFF3 ${outdir}/${prefix}.gff3 --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}_corrected.gtf --faa ${outdir}/${prefix}_corrected.faa --dir ${outdir} --output ${prefix}.ML
[ ! -f "${outdir}/${prefix}.ML_MLresult_classification.txt" ] && sqanti3_filter.py ML ${outdir}/${prefix}_classification.txt    --isoAnnotGFF3 ${outdir}/${prefix}.gff3 --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}_corrected.gtf --faa ${outdir}/${prefix}_corrected.faa --dir ${outdir} --output ${prefix}.ML

# Rescue
echo sqanti3_rescue.py rules --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}.rules.filtered.gtf --refGTF ${gtf} --refGenome ${genome} --refClassif ${outdir}/${prefix}_classification.txt --dir ${outdir} --output ${prefix}.rescueRules --json ${filter} ${outdir}/${prefix}.rules_RulesFilter_result_classification.txt
[ ! -f "${outdir}/${prefix}.rescueRules_rescued.gtf" ] && sqanti3_rescue.py rules --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}.rules.filtered.gtf --refGTF ${gtf} --refGenome ${genome} --refClassif ${outdir}/${prefix}_classification.txt --dir ${outdir} --output ${prefix}.rescueRules --json ${filter} ${outdir}/${prefix}.rules_RulesFilter_result_classification.txt
echo sqanti3_rescue.py ml    --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}.ML.filtered.gtf    --refGTF ${gtf} --refGenome ${genome} --refClassif ${outdir}/${prefix}_classification.txt --dir ${outdir} --output ${prefix}.rescueML    --randomforest ${outdir}/randomforest.RData ${outdir}/${prefix}.ML_MLresult_classification.txt
sqanti3_rescue.py ml    --isoforms ${outdir}/${prefix}_corrected.fasta --gtf ${outdir}/${prefix}.ML.filtered.gtf    --refGTF ${gtf} --refGenome ${genome} --refClassif ${outdir}/${prefix}_classification.txt --dir ${outdir} --output ${prefix}.rescueML    --randomforest ${outdir}/randomforest.RData ${outdir}/${prefix}.ML_MLresult_classification.txt

