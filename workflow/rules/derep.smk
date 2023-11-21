
#############
### RULES ###
#############

# TODO: merging of mixed PE/SE samples is not working, since it needs to be decided how they are merged
rule merge_lanes:
    input:
        lambda w: expand("results/reads/trim/{trimmer}/{sample}_{library}_{lane}_{read_type_trim}.fastq.gz", trimmer=config["reads"]["trim"]["tool"], lane=units.loc[(w.sample, w.library)].lane, allow_missing=True),
    output:
        fq = temp("temp/reads/derep/merge_lanes/{sample}_{library}_{read_type_trim}.fastq.gz"),
    log:
        "logs/reads/derep/merge_lanes/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/derep/merge_lanes/{sample}_{library}_{read_type_trim}.tsv"
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
        temp(touch("temp/reads/derep/loglog/{sample}_{library}_{read_type_trim}.flag")),
    log:
        "logs/reads/derep/loglog/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/derep/loglog/{sample}_{library}_{read_type_trim}.tsv"
    params:
        extra = "seed=1234 k={k} ignorebadquality".format(k=config["reads"]["extension"]["k"]),
    threads: 1
    resources:
        mem = lambda w, attempt: f"{5 * attempt} GiB",
        runtime = lambda w, attempt: f"{30 * attempt} m",
    wrapper:
        wrapper_ver + "/bio/bbtools/loglog"



def _get_filtermem(log, table_cap, bits, hashes):
    with open(str(log), "r") as f:
        cardinality_lines = list(filter(lambda x: re.search(r'^Cardinality:', x), f.readlines()))
        assert len(cardinality_lines) == 1, "several cardinality values found"
        cardinality = int(cardinality_lines[0].strip().split(" ")[-1])
        return int(cardinality*bits*hashes/8/table_cap)


rule read_extension:
    input:
        sample = [rules.merge_lanes.output.fq],
        flag = rules.loglog.output,
        tsv = rules.loglog.log,
    output:
        out = temp("temp/reads/derep/tadpole/{sample}_{library}_{read_type_trim}.fastq.gz"),
        discarded=temp("temp/reads/derep/tadpole/{sample}_{library}_{read_type_trim}.discarded.fastq.gz"),
    log:
        "logs/reads/derep/tadpole/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/derep/tadpole/{sample}_{library}_{read_type_trim}.tsv"
    params:
        mode = "extend",
        extra = lambda w, input: "k={k} filtermem={c} ".format(k=config["reads"]["extension"]["k"], c=_get_filtermem(input.tsv, table_cap=0.5, bits=16, hashes=3)) + check_cmd(config["reads"]["extension"]["params"], forbidden_args = ["threads", "in", "filtermem", "k", "out"]),
    threads: 24
    resources:
        mem = lambda w, attempt: f"{300 * attempt} GiB",
        runtime = lambda w, attempt: f"{2 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/bbtools/tadpole"



rule vsearch:
    input:
        fastx_uniques = rules.read_extension.output.out if is_activated("reads/extension") else rules.merge_lanes.output.fq,
    output:
        fastqout = temp("temp/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.fastq.gz"),
        log = "stats/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.log",
    log:
        "logs/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.tsv"
    params:
        extra = check_cmd(config["reads"]["derep"]["params"], forbidden_args = ["--fastx_uniques", "--fastqout", "--sizein", "--sizeout"]),
    threads: 1
    resources:
        mem = lambda w, attempt: f"{100 * attempt} GiB",
        runtime = lambda w, attempt: f"{5 * attempt} h",
    wrapper:
        "vsearch_log/bio/vsearch"



rule seqkit:
    input:
        fastx = rules.read_extension.output if is_activated("reads/extension") else rules.merge_lanes.output.fq,
    output:
        fastx = temp("temp/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.fastq.gz"),
        dup_num = "stats/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.dup.tsv"
    log:
        "logs/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.tsv"
    params:
        command = "rmdup",
        extra = "--ignore-case --by-seq " + check_cmd(config["reads"]["derep"]["params"], forbidden_args = ["-j", "--threads", "-s", "--by-seq", "-i", "--ignore-case", "-D", "--dup-num-file", "-o", "--out-file"]),
    threads: 10
    resources:
        mem = lambda w, attempt: f"{75 * attempt} GiB",
        runtime = lambda w, attempt: f"{2 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/seqkit"



##########
### QC ###
##########

rule seqkit_stats:
    input:
        fastx = "temp/reads/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz"
    output:
        stats = temp("stats/reads/{tool}/{sample}_{library}_{read_type_trim}.tsv"),
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
        runtime = lambda w, attempt: f"{30 * attempt} m",
    wrapper:
        wrapper_ver + "/bio/seqkit"
