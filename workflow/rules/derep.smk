
#############
### RULES ###
#############

if config["reads"]["derep"]["tool"] == "vsearch":
    rule vsearch:
        input:
            fastx_uniques = rules.extend_tadpole.output.out if is_activated("reads/extension") else rules.merge_lanes.output.fq,
        output:
            fastqout = temp("temp/reads/derep/{sample}_{library}_{read_type_trim}.fastq.gz"),
            log = "stats/reads/derep/{sample}_{library}_{read_type_trim}.log",
        log:
            "logs/reads/derep/{sample}_{library}_{read_type_trim}.log",
        benchmark:
            "benchmarks/reads/derep/{sample}_{library}_{read_type_trim}.jsonl"
        params:
            extra = config["reads"]["derep"]["params"],
        priority: 10
        threads: 1
        resources:
            mem = lambda w, attempt: f"{100 * attempt} GiB",
            runtime = lambda w, attempt: f"{5 * attempt} h",
        wrapper:
            f"{wrapper_ver}/bio/vsearch"


elif config["reads"]["derep"]["tool"] == "seqkit":
    rule seqkit:
        input:
            fastx = rules.extend_tadpole.output if is_activated("reads/extension") else rules.merge_lanes.output.fq,
        output:
            fastx = temp("temp/reads/derep/{sample}_{library}_{read_type_trim}.fastq.gz"),
            # touch() needed, since file is not created if no dup reads
            dup_num = touch("stats/reads/derep/{sample}_{library}_{read_type_trim}.dup.tsv"),
        log:
            "logs/reads/derep/{sample}_{library}_{read_type_trim}.log"
        benchmark:
            "benchmarks/reads/derep/{sample}_{library}_{read_type_trim}.jsonl"
        params:
            command = "rmdup",
            extra = "--ignore-case --by-seq " + config["reads"]["derep"]["params"],
        priority: 10
        threads: 10
        resources:
            mem = lambda w, attempt, input: f"{(3e-2 * input.size_mb + 50) * attempt} GiB",
            runtime = lambda w, attempt, input: f"{max(2e-4 * input.size_mb, 0.5) * attempt} h",
        wrapper:
            f"{wrapper_ver}/bio/seqkit"
