#############
### RULES ###
#############


rule seqkit_fx2tab:
    input:
        fastx="<temp>/reads/derep/{sample}_{library}_{read_type_trim}.fastq.gz",
    output:
        tsv=temp(
            "<temp>/reads/represent/fx2tab/{sample}_{library}_{read_type_trim}.tsv"
        ),
    log:
        "<logs>/reads/represent/fx2tab/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "<benchmarks>/reads/represent/fx2tab/{sample}_{library}_{read_type_trim}.jsonl"
    threads: 10
    resources:
        mem=lambda w, attempt: f"{1* attempt} GiB",
        runtime=lambda w, attempt: f"{15* attempt} m",
    params:
        command="fx2tab",
        extra="--name --only-id",
    wrapper:
        "v7.9.1/bio/seqkit"


rule seqkit_grep:
    input:
        fastx=rules.extend_tadpole.input.sample,
        pattern=rules.seqkit_fx2tab.output.tsv,
    output:
        fastx=temp(
            "<temp>/reads/represent/grep/{sample}_{library}_{read_type_trim}.fastq.gz"
        ),
    log:
        "<logs>/reads/represent/grep/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "<benchmarks>/reads/represent/grep/{sample}_{library}_{read_type_trim}.jsonl"
    threads: 10
    resources:
        mem=lambda w, attempt: f"{10* attempt} GiB",
        runtime=lambda w, attempt: f"{30* attempt} m",
    params:
        command="grep",
        extra="--delete-matched",
    wrapper:
        "v7.9.1/bio/seqkit"
