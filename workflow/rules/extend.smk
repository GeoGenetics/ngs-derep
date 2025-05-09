#############
### RULES ###
#############


# TODO: merging of mixed PE/SE samples is not working, since it needs to be decided how they are merged
rule merge_lanes:
    input:
        lambda w: expand(
            "results/reads/trim/{sample}_{library}_{lane}_{read_type_trim}.fastq.gz",
            lane=units.loc[(w.sample, w.library)].lane,
            allow_missing=True,
        ),
    output:
        fq=temp("temp/reads/merge_lanes/{sample}_{library}_{read_type_trim}.fastq.gz"),
    log:
        "logs/reads/merge_lanes/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/merge_lanes/{sample}_{library}_{read_type_trim}.jsonl"
    threads: 1
    resources:
        mem=lambda w, attempt: f"{1* attempt} GiB",
        runtime=lambda w, attempt: f"{1* attempt} h",
    shell:
        "cat {input} > {output}"


rule loglog:
    input:
        sample=[rules.merge_lanes.output.fq],
    output:
        temp(touch("temp/reads/extend/loglog/{sample}_{library}_{read_type_trim}.flag")),
    log:
        "logs/reads/extend/loglog/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/extend/loglog/{sample}_{library}_{read_type_trim}.jsonl"
    params:
        command="loglog.sh",
        extra="seed=1234 k={k} ignorebadquality".format(k=config["extension"]["k"]),
    threads: 1
    resources:
        mem=lambda w, attempt: f"{1* attempt} GiB",
        runtime=lambda w, attempt: f"{15* attempt} m",
    wrapper:
        f"{wrapper_ver}/bio/bbtools"


def _get_filtermem(log, table_cap, bits, hashes):
    import sys

    with open(str(log), "r") as f:
        cardinality_lines = list(
            filter(lambda x: re.search(r"^Cardinality:", x), f.readlines())
        )
        assert len(cardinality_lines) == 1, "several cardinality values found"
        cardinality = int(cardinality_lines[0].strip().split(" ")[-1])
        if cardinality == sys.maxsize:
            cardinality = 0
        return int(cardinality * bits * hashes / 8 / table_cap)


rule extend_tadpole:
    input:
        sample=[rules.merge_lanes.output.fq],
        flag=[rules.loglog.log, rules.loglog.output],
    output:
        out=temp(
            "temp/reads/extend/tadpole/{sample}_{library}_{read_type_trim}.fastq.gz"
        ),
    log:
        "logs/reads/extend/tadpole/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/extend/tadpole/{sample}_{library}_{read_type_trim}.jsonl"
    params:
        command="tadpole.sh",
        mode="extend",
        extra=lambda w, input: "k={k} filtermem={c} {extra}".format(
            k=config["extension"]["k"],
            c=_get_filtermem(input.flag[0], table_cap=0.5, bits=16, hashes=3),
            extra=config["extension"]["params"],
        ),
    threads: 10
    resources:
        mem=lambda w, attempt: f"{100* attempt} GiB",
        runtime=lambda w, attempt: f"{1* attempt} h",
    wrapper:
        f"{wrapper_ver}/bio/bbtools"


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
        html="stats/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}.html",
        zip="stats/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}_fastqc.zip",
    log:
        "logs/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/fastqc/{tool}/{sample}_{library}_{read_type_trim}.jsonl"
    threads: 2
    resources:
        # Memory is hard-coded to 250M per thread (https://github.com/bcbio/bcbio-nextgen/issues/2989)
        mem=lambda w, threads: f"{512* threads} MiB",
        runtime=lambda w, attempt: f"{1* attempt} h",
    wrapper:
        f"{wrapper_ver}/bio/fastqc"
