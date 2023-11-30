
assert not (is_activated("reads/extension") and not is_activated("reads/derep")), "You specified read extension WITHOUT dereplication, but this will lead to loosing information about DNA damage patterns. Are you sure?"


rule seqkit_fx2tab:
    input:
        fastx = "temp/reads/derep/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz",
    output:
        tsv = temp("temp/reads/represent/fx2tab/{sample}_{library}_{read_type_trim}.{tool}.tsv"),
    log:
        "logs/reads/represent/fx2tab/{sample}_{library}_{read_type_trim}.{tool}.log"
    benchmark:
        "benchmarks/reads/represent/fx2tab/{sample}_{library}_{read_type_trim}.{tool}.tsv"
    params:
        command = "fx2tab",
        extra = "--name"
    threads: 10
    resources:
        mem = lambda w, attempt: f"{1 * attempt} GB",
        runtime = lambda w, attempt: f"{30 * attempt} m",
    wrapper:
        wrapper_ver + "/bio/seqkit"


rule seqkit_grep:
    input:
        fastx = rules.read_extension.input.sample,
        pattern = rules.seqkit_fx2tab.output.tsv,
    output:
        fastx = temp("temp/reads/represent/grep/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz"),
    log:
        "logs/reads/represent/grep/{tool}/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/represent/grep/{tool}/{sample}_{library}_{read_type_trim}.tsv"
    params:
        command = "grep",
        extra = "--by-name --delete-matched",
    threads: 10
    resources:
        mem = lambda w, attempt: f"{50 * attempt} GB",
        runtime = lambda w, attempt: f"{5 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/seqkit"



##########
### QC ###
##########

rule nonpareil:
    input:
#        rules.seqkit_grep.output.fastx,
        "temp/reads/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz"
    output:
        redund_sum = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.npo",
        redund_val = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.npa",
        mate_distr = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.npc",
        log = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.log",
    log:
        "logs/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.tsv",
    params:
        alg = "kmer",
        extra = "-F",
    threads: 2
    resources:
        mem = lambda w, attempt: f"{10 * attempt} GB",
        runtime = lambda w, attempt: f"{1 * attempt} h",
        # tmpdir used for FASTQ decompression, since nonpareil does not support gziped input
#        tmpdir = get_tmp(large = True),
    wrapper:
         wrapper_ver + "/bio/nonpareil/infer"


rule nonpareil_plot:
    input:
        npo = rules.nonpareil.output.redund_sum,
    output:
        plot = "reports/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.pdf",
        model = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.RData",
    log:
        "logs/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.plot.log",
    params:
        enforce_consistency = True,
        star = 90,
        correction_factor = True,
    localrule: True
    threads: 1
    resources:
        mem = lambda w, attempt: f"{5 * attempt} GB",
        runtime = lambda w, attempt: f"{1 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/nonpareil/plot"
