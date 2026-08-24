#############
### RULES ###
#############


# TODO: merging of mixed PE/SE samples is not working, since it needs to be decided how they are merged
rule merge_lanes:
    input:
        lambda w: expand(
            "<results>/reads/trim/{sample}_{library}_{lane}_{read_type_trim}.fastq.gz",
            lane=units.loc[(w.sample, w.library)].lane,
            allow_missing=True,
        ),
    output:
        fq=temp("<temp>/reads/merge_lanes/{sample}_{library}_{read_type_trim}.fastq.gz"),
    log:
        "<logs>/reads/merge_lanes/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "<benchmarks>/reads/merge_lanes/{sample}_{library}_{read_type_trim}.jsonl"
    threads: 1
    resources:
        mem=lambda w, attempt: f"{1* attempt} GiB",
        runtime=lambda w, attempt: f"{1* attempt} h",
    shell:
        "cat {input} > {output}"


##########
### QC ###
##########


rule fastqc:
    input:
        lambda w: expand(
            "{path}/reads/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz",
            path="results" if w.tool == "low_complexity" else "temp",
            allow_missing=True,
        ),
    output:
        html="<stats>/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}.html",
        zip="<stats>/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}_fastqc.zip",
    log:
        "<logs>/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "<benchmarks>/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}.jsonl"
    wildcard_constraints:
        tool="merge_lanes|extend/tadpole|derep|represent/grep|low_complexity",
    threads: 4
    resources:
        mem=lambda w, attempt: f"{3* attempt} GiB",
        runtime=lambda w, attempt: f"{2* attempt} h",
    wrapper:
        "v9.15.0/bio/fastqc"
