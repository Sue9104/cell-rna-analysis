# Workflow for Third Generation Sequencing 

## Tools

- minimap2
- SQANTI3
- tappAS

## Install

```shell
make install && make environment
```

## Workflow
### Prepare pacbio bam

```
python tools/fq2bam.py <fq.gz> <out.bam> <sample_name>
```

### Run Isoseq3

```
tools/isoseq3.cmd.sh <pacbio.bam> <prefix>
```
