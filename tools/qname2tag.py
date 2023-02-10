import pandas as pd
import sys
import io
import subprocess

infile = sys.argv[1]
outfile = sys.argv[2]
prefix = sys.argv[3]
# unaligned sam
## remember to change RG id, PU
cmd = """gatk FastqToSam -F1 {infile} -O {out}.sam -SM {name} -LB {name} -PM SEQUELII -PL PACBIO -PU m64236_221115_103721 -RG 661095a9 -SO unsorted -DS "READTYPE=SEGMENT;SOURCE=CCS;BINDINGKIT=101-894-200;SEQUENCINGKIT=101-826-100;BASECALLERVERSION=5.0.0;FRAMERATEHZ=100.000000" """.format(
    infile = infile, out = outfile, name = prefix)
print(cmd)
subprocess.run(cmd, shell=True)

# generate tag
cmd = """cut -f1 {}.sam | sed '1,2d' """.format(outfile)
process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
csv = io.StringIO(process.stdout.read().decode())
data = pd.read_csv(csv, header=None)
infos = data.squeeze().str.split("/")
zm = infos.apply(lambda x: int(x[1]))
qs = infos.apply(lambda x: int(x[3].split('_')[0]))
qe = infos.apply(lambda x: int(x[3].split('_')[1]))
df = pd.DataFrame({"zm": zm, "qs": qs, "qe": qe})
text = df.apply(lambda x: "zm:i:{}\tqs:i:{}\tqe:i:{}\tma:i:0\tnp:i:1\trq:f:0.999355\tac:B:i,8,0,8,0".format(
    x["zm"], x["qs"], x["qe"]), axis=1)
#rank = df.groupby(["zm"], group_keys=False).apply(lambda x: x["qs"].rank().astype(int)).rename("rank")
#df = pd.concat([df, rank], axis=1)
#text = df.apply(lambda x: "zm:i:{}\tqs:i:{}\tqe:i:{}\tdi:i:{}\tdl:i:{}\tdr:i:{}".format(
#    x["zm"], x["qs"], x["qe"], x["rank"] - 1, x["rank"] - 1, x["rank"]), axis=1)
tag = outfile + ".tmp"
text.to_csv(tag, index=False, header=False, sep = '|')
cmd1 = """sed -i '1s|^|\\n|g; 1s|^|=\\n|g' {}""".format(tag, tag)
print(cmd1)
subprocess.run(cmd1, shell=True)

# paste tag and sam
# HD tag is important!!!
cmd2 ="""paste {out}.sam {out}.tmp| sed '1s|=$|pb:5.0.0|g; 1s|unsorted|unknown|g' | samtools view -bS - > {out}""".format(out=outfile)
print(cmd2)
subprocess.run(cmd2, shell=True)
