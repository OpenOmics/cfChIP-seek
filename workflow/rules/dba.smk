# TODO: This Snakefile needs to be completely refactored.
# Python standard library
from os.path import join
import os

# Local imports
from scripts.common import (
    allocated
)

# Constants
effectivegenomesize = config['references']['EFFECTIVEGENOMESIZE']
reflen = config['references']['REFLEN']

# Helper functions
def peaks_per_chrom(file, chrom):
    """
    Takes a peak file as input and counts how many peaks 
    there are on a given chromosome of interest.
    """
    f = open(file, 'r')
    datain = f.readlines()
    f.close()
    data = [row.strip().split('\t')[0] for row in datain]
    return(data.count(chrom))


def outputIDR(groupswreps, groupdata, chip2input, tools):
    """
    Produces the correct output files for IDR. All supposed replicates
    should be directly compared when possible using IDR. IDR malfunctions
    with bed files and GEM so it will not run with either of those.
    Because there is no q-value calculated for SICER when there is no 
    input file, those samples are also ignored.
    """
    IDRgroup, IDRsample1, IDRsample2, IDRpeaktool = [], [], [], []
    for group in groupswreps:
        nsamples = len(groupdata[group])
        for i in range(nsamples):
            ctrlTF = chip2input[groupdata[group][i]] != ""
            for j in range(i+1,nsamples):
                if ctrlTF == (chip2input[groupdata[group][j]] != ""):
                    if ctrlTF == False:
                        tooltmp = [ tool for tool in tools if tool != "sicer" ]
                    else:
                        tooltmp = tools			           
                    IDRgroup.extend([group] * len(tooltmp))
                    IDRsample1.extend([groupdata[group][i]] * len(tooltmp))
                    IDRsample2.extend([groupdata[group][j]] * len(tooltmp))
                    IDRpeaktool.extend(tooltmp)
    return( IDRgroup, IDRsample1, IDRsample2, IDRpeaktool )


def zip_peak_files(chips, PeakTools, PeakExtensions):
    """Making input file names for FRiP"""
    zipSample, zipTool, zipExt = [], [], []
    for chip in chips:
        for PeakTool in PeakTools:
            zipSample.append(chip)
            zipTool.append(PeakTool)
            zipExt.append(PeakExtensions[PeakTool])
    return(zipSample, zipTool, zipExt)


def calc_effective_genome_fraction(effectivesize, genomefile):
    """
    calculate the effective genome fraction by calculating the
    actual genome size from a .genome-like file and then dividing
    the effective genome size by that number
    """
    lines=list(map(lambda x:x.strip().split("\t"),open(genomefile).readlines()))
    genomelen=0
    for chrom,l in lines:
        if not "_" in chrom and chrom!="chrX" and chrom!="chrM" and chrom!="chrY":
            genomelen+=int(l)
    return(str(float(effectivesize)/ genomelen))


def zip_contrasts(contrast, PeakTools):
    """making output file names for differential binding analyses"""
    zipGroup1, zipGroup2, zipTool, contrasts = [], [], [], []
    for g1, g2 in contrast:
        for PeakTool in PeakTools:
            zipGroup1.append(g1)
            zipGroup2.append(g2)
            zipTool.append(PeakTool)
            contrasts.append( g1 + "_vs_" + g2 + "-" + PeakTool )
    return(zipGroup1, zipGroup2, zipTool, contrasts)


# DEFINING SAMPLES
chips = config['project']['peaks']['chips']
chip2input = config['project']['peaks']['inputs']
uniq_inputs = list(sorted(set([v for v in chip2input.values() if v])))

sampleswinput = []

for inp in chip2input:
        if chip2input[inp] != 'NA' and chip2input[inp] != '':
                sampleswinput.append(inp)

groupdata = config['project']['groups']

groupdatawinput = {}
groupswreps = []

for group, chipsamples in groupdata.items() :
    tmp = [ ]
    if len(chipsamples) > 1:
        groupswreps.append(group)
    for chip in chipsamples :
        if chip in samples:
            tmp.append(chip)
            input = chip2input[chip]
            if input != 'NA' and input != '':
                tmp.append(input)
    if len(tmp) != 0:
        groupdatawinput[group]=set(tmp)

groups = list(groupdatawinput.keys())

reps=""
if len(groupswreps) > 0:
    reps="yes"

contrast = config['project']['contrast']


# PREPARING TO DEAL WITH A VARIED SET OF PEAKCALL TOOLS
macsN_dir = "macsNarrow"
gem_dir = "gem"
macsB_dir = "macsBroad"
sicer_dir = "sicer"

PeakTools_narrow = [macsN_dir]

PeakTools = PeakTools_narrow 
PeakToolsNG = [ tool for tool in PeakTools if tool != "gem" ]

PeakExtensions = { 'macsNarrow': '_peaks.narrowPeak', 'macsBroad': '_peaks.broadPeak',
                   'sicer': '_broadpeaks.bed', 'gem': '.GEM_events.narrowPeak' ,
                   'MANorm': '_all_MA.bed', 'DiffbindEdgeR': '_Diffbind_EdgeR.bed',
                   'DiffbindDeseq2': '_Diffbind_Deseq2.bed', 'DiffbindConsensus': '_Diffbind_consensusPeaks.bed'}

FileTypesDiffBind = { 'macsNarrow': 'narrowPeak', 'macsBroad': 'narrowPeak',
                    'sicer': 'bed', 'gem': 'narrowPeak' }

PeakExtensionsIDR = { 'macsNarrow': '_peaks.narrowPeak', 'macsBroad': '_peaks.broadPeak',
                      'sicer': '_sicer.broadPeak' }

FileTypesIDR = { 'macsNarrow': 'narrowPeak', 'macsBroad': 'broadPeak',
                 'sicer': 'broadPeak' }

RankColIDR = { 'macsNarrow': 'q.value', 'macsBroad': 'q.value',
               'sicer': 'q.value' }

UropaCats = ["protTSS"]

IDRgroup, IDRsample1, IDRsample2, IDRpeaktool =	outputIDR(groupswreps, groupdata, chip2input, PeakToolsNG)

zipSample, zipTool, zipExt = zip_peak_files(chips, PeakTools, PeakExtensions)
zipGroup1, zipGroup2, zipToolC, contrasts = zip_contrasts(contrast, PeakTools)


# CREATING DIRECTORIES
bam_dir='bam'
qc_dir='PeakQC'

idr_dir = 'IDR'
memechip_dir = "MEME"
homer_dir = "HOMER_motifs"
uropa_dir = "UROPA_annotations"
diffbind_dir = "DiffBind"
manorm_dir = "MANorm"

otherDirs = [qc_dir, homer_dir, uropa_dir]
if reps == "yes":
    otherDirs.append(idr_dir)
    otherDirs.append(diffbind_dir)

for d in PeakTools + otherDirs:
        if not os.path.exists(join(workpath,d)):
                os.mkdir(join(workpath,d))


# RULE ALL
if reps == "yes":
    rule ChIPseq:
        input:
            expand(join(workpath,macsN_dir,"{name}","{name}_peaks.narrowPeak"),name=chips),
            expand(join(workpath,qc_dir,"{Group}.FRiP_barplot.pdf"),Group=groups),
            expand(join(workpath,qc_dir,'{PeakTool}_jaccard.txt'),PeakTool=PeakTools),
            expand(join(workpath,uropa_dir,'{PeakTool}','{name}_{PeakTool}_uropa_{type}_allhits.txt'),PeakTool=PeakTools,name=chips,type=UropaCats),
            expand(join(workpath, uropa_dir,diffbind_dir,'{name}_{PeakTool}_uropa_{type}_allhits.txt'),PeakTool=['DiffbindEdgeR','DiffbindDeseq2','DiffbindConsensus'],name=contrasts,type=UropaCats),
            expand(join(workpath,diffbind_dir,"{group1}_vs_{group2}-{PeakTool}","{group1}_vs_{group2}-{PeakTool}_Diffbind.html"),zip,group1=zipGroup1,group2=zipGroup2,PeakTool=zipToolC),
        output:
            touch(join(workpath, 'dba.done'))
else:
    rule ChIPseq:
        input:
            expand(join(workpath,macsN_dir,"{name}","{name}_peaks.narrowPeak"),name=chips),
            expand(join(workpath,qc_dir,"{Group}.FRiP_barplot.pdf"),Group=groups),
            expand(join(workpath,qc_dir,'{PeakTool}_jaccard.txt'),PeakTool=PeakTools),
            expand(join(workpath,uropa_dir,'{PeakTool}','{name}_{PeakTool}_uropa_{type}_allhits.txt'),PeakTool=PeakTools,name=chips,type=UropaCats),
            expand(join(workpath,uropa_dir,'{PeakTool}','{name}_{PeakTool}_uropa_{type}_allhits.txt'),PeakTool="MANorm",name=contrasts,type=UropaCats),
            expand(join(workpath,manorm_dir,"{group1}_vs_{group2}-{tool}","{group1}_vs_{group2}-{tool}_all_MAvalues.xls"),zip,group1=zipGroup1,group2=zipGroup2,tool=zipToolC),
        output:
            touch(join(workpath, 'dba.done'))


# INDIVIDUAL RULES
rule MACS2_narrow:
    input:
        chip = join(workpath,bam_dir,"{name}.Q5DD.bam"),
    output:
        join(workpath,macsN_dir,"{name}","{name}_peaks.narrowPeak"),
    params:
        rname='MACS2_narrow',
        gsize=config['references']['EFFECTIVEGENOMESIZE'],
        macsver=config['tools']['MACSVER'],
        ctrl = lambda w : join(workpath,bam_dir,chip2input[w.name] + ".Q5DD.bam"),
    shell: """
    module load {params.macsver};
    if [ {params.ctrl} != "{workpath}/{bam_dir}/.Q5DD.bam" ]; then
        macs2 callpeak -t {input.chip} -c {params.ctrl} -g {params.gsize} -n {wildcards.name} \
              --outdir {workpath}/{macsN_dir}/{wildcards.name} -q 0.01 --keep-dup="all" -f "BAMPE";
    else
        macs2 callpeak -t {input.chip} -g {params.gsize} -n {wildcards.name} \
              --outdir {workpath}/{macsN_dir}/{wildcards.name} -q 0.01 --keep-dup="all" -f "BAMPE";
    fi
    """


rule jaccard:
    input:
        lambda w: [ join(workpath, w.PeakTool, chip, chip + PeakExtensions[w.PeakTool]) for chip in chips ],
    output:
        join(workpath,qc_dir,'{PeakTool}_jaccard.txt'),
    params:
        rname="jaccard",
        outroot = lambda w: join(workpath,qc_dir,w.PeakTool),
        script=join(workpath,"workflow","scripts","jaccard_score.py"),
        genome = config['references']['REFLEN']
    envmodules:
        config['tools']['BEDTOOLSVER']
    shell: """
    python {params.script} -i "{input}" -o "{params.outroot}" -g {params.genome}
    """


rule FRiP:
     input:
        bed = lambda w: [ join(workpath, w.PeakTool, chip, chip + PeakExtensions[w.PeakTool]) for chip in chips ],
        bam = join(workpath,bam_dir,"{Sample}.Q5DD.bam"),
     output:
        temp(join(workpath,qc_dir,"{PeakTool}.{Sample}.Q5DD.FRiP_table.txt")),
     params:
        rname="frip",
        pythonver="python/3.5",
        outroot = lambda w: join(workpath,qc_dir,w.PeakTool),
        script=join(workpath,"workflow","scripts","frip.py"),
        genome = config['references']['REFLEN']
     shell: """
    module load {params.pythonver}
    python {params.script} -p "{input.bed}" -b "{input.bam}" -g {params.genome} -o "{params.outroot}"
    """


rule FRiP_plot:
     input:
        expand(join(workpath,qc_dir,"{PeakTool}.{Sample}.Q5DD.FRiP_table.txt"), PeakTool=PeakTools, Sample=samples),
     output:
        expand(join(workpath, qc_dir, "{Group}.FRiP_barplot.pdf"),Group=groups),
     params:
        rname="frip_plot",
        Rver="R/3.5",
        script=join(workpath,"workflow","scripts","FRiP_plot.R"),
     shell: """
    module load {params.Rver}
    Rscript {params.script} {workpath}
    """


rule UROPA:
    input:
        lambda w: [ join(workpath, w.PeakTool1, w.name, w.name + PeakExtensions[w.PeakTool2]) ]
    output:
        join(workpath, uropa_dir, '{PeakTool1}', '{name}_{PeakTool2}_uropa_{type}_allhits.txt')
    params:
        rname="uropa",
        uropaver = config['tools']['UROPAVER'],
        fldr = join(workpath, uropa_dir, '{PeakTool1}'),
        json = join(workpath, uropa_dir, '{PeakTool1}','{name}.{PeakTool2}.{type}.json'),
        outroot = join(workpath, uropa_dir, '{PeakTool1}','{name}_{PeakTool2}_uropa_{type}'),
        gtf = config['references']['GTFFILE'],
        threads = 4,
    shell: """
    module load {params.uropaver};
    if [ ! -e {params.fldr} ]; then mkdir {params.fldr}; fi
    echo '{{"queries":[ ' > {params.json}
    if [ '{wildcards.type}' == 'prot' ]; then
         echo '      {{ "feature":"gene","distance":5000,"filter.attribute":"gene_type","attribute.value":"protein_coding","show.attributes":["gene_id", "gene_name","gene_type"] }},' >> {params.json}
         echo '      {{ "feature":"gene","filter.attribute":"gene_type","attribute.value":"protein_coding","show.attributes":["gene_id", "gene_name","gene_type"] }}],' >> {params.json}
    elif [ '{wildcards.type}' == 'genes' ]; then
         echo '      {{ "feature":"gene","distance":5000,"show.attributes":["gene_id", "gene_name","gene_type"] }},' >> {params.json}
         echo '      {{ "feature":"gene","show.attributes":["gene_id", "gene_name","gene_type"] }}],' >> {params.json}
    elif [ '{wildcards.type}' == 'protSEC' ]; then
         echo '      {{ "feature":"gene","distance":[3000,1000],"filter.attribute":"gene_type","attribute.value":"protein_coding","feature.anchor":"start","show.attributes":["gene_id", "gene_name","gene_type"] }},' >> {params.json}
         echo '      {{ "feature":"gene","distance":3000,"filter.attribute":"gene_type","attribute.value":"protein_coding","feature.anchor":"end","show.attributes":["gene_id", "gene_name","gene_type"] }},' >> {params.json}
         echo '      {{ "feature":"gene","distance":100000,"filter.attribute":"gene_type","attribute.value":"protein_coding","feature.anchor":"center","show.attributes":["gene_id", "gene_name","gene_type"] }},' >> {params.json}
         echo '      {{ "feature":"gene","distance":100000,"filter.attribute":"gene_type","attribute.value":"protein_coding","show.attributes":["gene_id", "gene_name","gene_type"] }}],' >> {params.json}
    else
         echo '      {{ "feature":"gene","distance":[3000,1000],"filter.attribute":"gene_type","attribute.value":"protein_coding","feature.anchor":"start","show.attributes":["gene_id", "gene_name","gene_type"] }},' >> {params.json}
         echo '      {{ "feature":"gene","distance":10000,"filter.attribute":"gene_type","attribute.value":"protein_coding","feature.anchor":"start","show.attributes":["gene_id", "gene_name","gene_type"] }},' >> {params.json}
         echo '      {{ "feature":"gene","distance":100000,"filter.attribute":"gene_type","attribute.value":"protein_coding","feature.anchor":"start","show.attributes":["gene_id", "gene_name","gene_type"] }}],' >> {params.json}

    fi
    echo '"priority":"Yes",' >> {params.json}
    echo '"gtf":"{params.gtf}",' >> {params.json}
    echo '"bed": "{input}" }}' >> {params.json}
    uropa -i {params.json} -p {params.outroot} -t {params.threads} -s
    """


rule diffbind:
    input:
        lambda w: [ join(workpath, w.PeakTool, chip, chip + PeakExtensions[w.PeakTool]) for chip in chips ]
    output:
        html = join(workpath,diffbind_dir,"{group1}_vs_{group2}-{PeakTool}","{group1}_vs_{group2}-{PeakTool}_Diffbind.html"),
        Deseq2 = join(workpath,diffbind_dir,"{group1}_vs_{group2}-{PeakTool}","{group1}_vs_{group2}-{PeakTool}_Diffbind_Deseq2.bed"),
        EdgeR = join(workpath,diffbind_dir,"{group1}_vs_{group2}-{PeakTool}","{group1}_vs_{group2}-{PeakTool}_Diffbind_EdgeR.bed"),
        consensus = join(workpath,diffbind_dir,"{group1}_vs_{group2}-{PeakTool}","{group1}_vs_{group2}-{PeakTool}_Diffbind_consensusPeaks.bed"),
    params:
        rname="diffbind",
        Rver = config['tools']['RVER'],
        rscript1 = join(workpath,"workflow","scripts","runDiffBind.R"),
        rscript2 = join(workpath,"workflow","scripts","DiffBind_ChIP-seq.Rmd"),
        projectID = 'cfChIP-seek',
        projDesc  = config['project']['version'],
        outdir    = join(workpath,diffbind_dir,"{group1}_vs_{group2}-{PeakTool}"),
        contrast  = "{group1}_vs_{group2}",
        csvfile   = join(workpath,diffbind_dir,"{group1}_vs_{group2}-{PeakTool}","{group1}_vs_{group2}-{PeakTool}_Diffbind_prep.csv"),
    run:
        samplesheet = [",".join(["SampleID","Condition", "Replicate", "bamReads", 
		      "ControlID", "bamControl", "Peaks", "PeakCaller"])]
        for condition in wildcards.group1,wildcards.group2:
            for chip in groupdata[condition]:
                file = join(workpath, wildcards.PeakTool, chip, chip + PeakExtensions[wildcards.PeakTool])
                replicate = str([ i + 1 for i in range(len(groupdata[condition])) if groupdata[condition][i]== chip ][0])
                bamReads = join(workpath, bam_dir, chip + ".Q5DD.bam")
                controlID = chip2input[chip]
                if controlID != "":
                    bamControl = join(workpath, bam_dir, controlID + ".Q5DD.bam")
                else:
                    bamControl = ""
                peaks = join(workpath, wildcards.PeakTool, chip, chip + PeakExtensions[wildcards.PeakTool])
                peakcaller = FileTypesDiffBind[wildcards.PeakTool]
                samplesheet.append(",".join([chip, condition, replicate, bamReads, 
						   controlID, bamControl, peaks, peakcaller]))

        f = open(params.csvfile, 'w')
        f.write ("\n".join(samplesheet))
        f.close()
        cmd1 = "module load {params.Rver}; cp {params.rscript2} {params.outdir}; cd {params.outdir}; "
        cmd2 = "Rscript {params.rscript1} '.' {output.html} {params.csvfile} '{params.contrast}' '{wildcards.PeakTool}' '{params.projectID}' '{params.projDesc}'"
        shell( cmd1 + cmd2 )


rule manorm:
    input: 
        bam1 = lambda w: join(workpath,bam_dir, groupdata[w.group1][0] + ".Q5DD.bam"),
        bam2 = lambda w: join(workpath,bam_dir, groupdata[w.group2][0] + ".Q5DD.bam"),
        ppqt = join(workpath,bam_dir, "Q5DD.ppqt.txt"),
        peak1 = lambda w: join(workpath, w.tool, groupdata[w.group1][0], groupdata[w.group1][0] + PeakExtensions[w.tool]),
        peak2 = lambda w: join(workpath, w.tool, groupdata[w.group2][0], groupdata[w.group2][0] + PeakExtensions[w.tool]),
    output:
        fldr = join(workpath,manorm_dir,"{group1}_vs_{group2}-{tool}"),
        xls = join(workpath,manorm_dir,"{group1}_vs_{group2}-{tool}","{group1}_vs_{group2}-{tool}_all_MAvalues.xls"),
        bed = temp(join(workpath,manorm_dir,"{group1}_vs_{group2}-{tool}","{group1}_vs_{group2}-{tool}_all_MA.bed")),
        wigA = join(workpath,manorm_dir,"{group1}_vs_{group2}-{tool}","output_tracks","{group1}_vs_{group2}_A_values.wig.gz"),
        wigM = join(workpath,manorm_dir,"{group1}_vs_{group2}-{tool}","output_tracks","{group1}_vs_{group2}_M_values.wig.gz"),
        wigP = join(workpath,manorm_dir,"{group1}_vs_{group2}-{tool}","output_tracks","{group1}_vs_{group2}_P_values.wig.gz"),
    params:
        rname='manorm',
        bedtoolsver=config['tools']['BEDTOOLSVER'],
        sample1= lambda w: groupdata[w.group1][0],
        sample2= lambda w: groupdata[w.group2][0],
        manormver="manorm/1.1.4"
    run:
        commoncmd1 = "if [ ! -e /lscratch/$SLURM_JOBID ]; then mkdir /lscratch/$SLURM_JOBID; fi "
        commoncmd2 = "cd /lscratch/$SLURM_JOBID; "
        commoncmd3 = "module load {params.manormver}; module load {params.bedtoolsver}; "
        cmd1 = "bamToBed -i {input.bam1} > bam1.bed; "
        cmd2 = "bamToBed -i {input.bam2} > bam2.bed; "
        cmd3 = "cut -f 1,2,3 {input.peak1} > peak1.bed; "
        cmd4 = "cut -f 1,2,3 {input.peak2} > peak2.bed; "
        file=list(map(lambda z:z.strip().split(),open(input.ppqt,'r').readlines()))
        extsize1 = [ ppqt[1] for ppqt in file if ppqt[0] == params.sample1 ][0]
        extsize2 = [ ppqt[1] for ppqt in file if ppqt[0] == params.sample2 ][0]
        cmd5 = "manorm --p1 peak1.bed --p2 peak2.bed --r1 bam1.bed --r2 bam2.bed --s1 " + extsize1  + " --s2 " + extsize2 + " -o {output.fldr} --name1 '" + wildcards.group1 + "' --name2 '" + wildcards.group2 + "'; "
        cmd6 = "gzip {output.fldr}/output_tracks/*wig; "
        cmd7 = "mv {output.fldr}/" + wildcards.group1 + "_vs_" + wildcards.group2 + "_all_MAvalues.xls {output.xls}; "
        cmd8 = "tail -n +2 {output.xls} | nl -w2 | awk -v OFS='\t' '{{print $2,$3,$4,$9$1,$6}}' > {output.bed}"
        shell(commoncmd1)