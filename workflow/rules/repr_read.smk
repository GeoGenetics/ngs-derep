#############
### RULES ###
#############

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
        mem = lambda w, attempt: f"{1 * attempt} GiB",
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
        extra = "--delete-matched",
    threads: 10
    resources:
        mem = lambda w, attempt: f"{50 * attempt} GiB",
        runtime = lambda w, attempt: f"{5 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/seqkit"
