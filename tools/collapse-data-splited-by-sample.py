import os
import re
import csv
import glob
import subprocess
import pandas as pd
import numpy as np
import argparse
parser = argparse.ArgumentParser( description='Isoseq Collapse Results Splited by Sample')
parser.add_argument( 'indir', type=str, help='input directory')
parser.add_argument( 'outdir', type=str, help='output file')
args = parser.parse_args()

outdir = args.outdir
if not os.path.exists(outdir):
    os.makedirs(outdir)

# lazy load for big files
def read_in_chunks(file_object, chunk_size=1048576):
    """Lazy function (generator) to read a file piece by piece.
    Default chunk size: 1M."""
    while True:
        data = file_object.read(chunk_size)
        if not data:
            break
        yield data

# read groups into sampledict
indir = args.indir
group_file = glob.glob("{}/*collapse.group.txt".format(indir))[0]
sampledict = {}
with open(group_file, mode='r') as f:
    data = csv.reader(f)
    for line in data:
        #transcript, molecule = line.strip().split("\t")
        transcript, molecule = line[0].split("\t")
        molecules = molecule.split(',')
        for molecule in molecules:
            sample, molecule = molecule.split('.')
            if sample not in sampledict.keys():
                sampledict[sample] = {transcript: [molecule]}
            elif transcript not in sampledict[sample].keys():
                sampledict[sample][transcript] = [molecule]
            else:
                sampledict[sample][transcript] += [molecule]
samples = sampledict.keys()
for sample in samples:
    sample_group_file = "{}/{}.collapse.group.txt".format(outdir, sample)
    groups = {transcript: ",".join(sampledict[sample][transcript])
              for transcript in sampledict[sample].keys()}
    groups = pd.DataFrame.from_dict(groups, orient="index")
    groups.to_csv(sample_group_file, header=False, sep='\t')
    sample_abundance_file = "{}/{}.collapse.abundance.txt".format(outdir, sample)
    abundances = {transcript: len(sampledict[sample][transcript])
                  for transcript in sampledict[sample].keys()}
    abundances = pd.DataFrame.from_dict(abundances, orient="index")
    abundances.to_csv(sample_abundance_file, sep='\t',
                      header=["count_fl"], index_label="pbid")

# read stat file
readstat_file = glob.glob("{}/*collapse.read_stat.txt".format(indir))[0]
for sample in samples:
    sample_readstat_file = "{}/{}.collapse.read_stat.txt".format(outdir, sample)
    cmd = "grep '^{sample}' {infile} | cat <(head -1 {infile}) - > {out}".format(
        sample = sample, infile = readstat_file, out = sample_readstat_file
    )
    subprocess.run(cmd, shell=True, executable='/bin/bash')
# collapsed gff
gff_file = glob.glob("{}/*collapse.gff".format(indir))[0]
transcriptdict = {}
with open(gff_file, mode='r') as f:
    data = csv.reader(f)
    for line in data:
        line = line[0]
        if line.startswith('#'):
            continue
        transcript = re.search('transcript_id "(?P<tran>PB.*?)"', line).group('tran')
        if transcript not in transcriptdict.keys():
            transcriptdict[transcript] = [line]
        else:
            transcriptdict[transcript] += [line]
for sample in samples:
    transcripts = sampledict[sample].keys()
    infos = ["\n".join(transcriptdict[transcript]) + "\n"
             for transcript in transcripts]
    sample_gff_file = "{}/{}.collapse.gff".format(outdir, sample)
    with open(sample_gff_file, mode='w') as f:
        f.write("##pacbio-collapse-version 1.0\n")
        f.writelines(infos)
