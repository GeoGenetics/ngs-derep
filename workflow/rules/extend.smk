
#############
### RULES ###
#############

# TODO: merging of mixed PE/SE samples is not working, since it needs to be decided how they are merged
rule merge_lanes:
    input:
        lambda w: expand("results/reads/trim/{sample}_{library}_{lane}_{read_type_trim}.fastq.gz", lane=units.loc[(w.sample, w.library)].lane, allow_missing=True),
    output:
        fq = temp("temp/reads/merge_lanes/{sample}_{library}_{read_type_trim}.fastq.gz"),
    log:
        "logs/reads/merge_lanes/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/merge_lanes/{sample}_{library}_{read_type_trim}.tsv"
    threads: 1
    resources:
        mem = lambda w, attempt: f"{1 * attempt} GiB",
        runtime = lambda w, attempt: f"{1 * attempt} h",
    shell:
        "cat {input} > {output}"



rule loglog:
    input:
        sample = [rules.merge_lanes.output.fq],
    output:
        temp(touch("temp/reads/extend/loglog/{sample}_{library}_{read_type_trim}.flag")),
    log:
        "logs/reads/extend/loglog/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/extend/loglog/{sample}_{library}_{read_type_trim}.tsv"
    params:
        command="loglog.sh",
        extra = "seed=1234 k={k} ignorebadquality".format(k=config["reads"]["extension"]["k"]),
    threads: 1
    resources:
        mem = lambda w, attempt: f"{5 * attempt} GiB",
        runtime = lambda w, attempt: f"{30 * attempt} m",
    wrapper:
        wrapper_ver + "/bio/bbtools"



def _get_filtermem(log, table_cap, bits, hashes):
    with open(str(log), "r") as f:
        cardinality_lines = list(filter(lambda x: re.search(r'^Cardinality:', x), f.readlines()))
        assert len(cardinality_lines) == 1, "several cardinality values found"
        cardinality = int(cardinality_lines[0].strip().split(" ")[-1])
        return int(cardinality*bits*hashes/8/table_cap)


rule read_extension:
    input:
        sample = [rules.merge_lanes.output.fq],
        flag = [rules.loglog.log, rules.loglog.output],
    output:
        out = temp("temp/reads/extend/tadpole/{sample}_{library}_{read_type_trim}.fastq.gz"),
    log:
        "logs/reads/extend/tadpole/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/extend/tadpole/{sample}_{library}_{read_type_trim}.tsv"
    params:
        command="tadpole.sh",
        mode = "extend",
        extra = lambda w, input: "k={k} filtermem={c} ".format(k=config["reads"]["extension"]["k"], c=_get_filtermem(input.flag[0], table_cap=0.5, bits=16, hashes=3)) + check_cmd(config["reads"]["extension"]["params"], forbidden_args = ["threads", "in", "filtermem", "k", "out"]),
    threads: 24
    resources:
        mem = lambda w, attempt: f"{300 * attempt} GiB",
        runtime = lambda w, attempt: f"{2 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/bbtools"



##########
### QC ###
##########

rule seqkit_stats:
    input:
        fastx = lambda w: expand("{path}/reads/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz", path = "results" if w.tool == "low_complexity" else "temp", allow_missing=True),
    output:
        stats = "stats/reads/{tool}/{sample}_{library}_{read_type_trim}.tsv",
    log:
        "logs/reads/stats/{tool}/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/stats/{tool}/{sample}_{library}_{read_type_trim}.tsv"
    params:
        command = "stats",
        extra = "--tabular --all"
    threads: 4
    resources:
        mem = lambda w, attempt: f"{1 * attempt} GiB",
        runtime = lambda w, attempt: f"{2 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/seqkit"
