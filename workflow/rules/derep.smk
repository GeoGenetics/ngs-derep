
#############
### RULES ###
#############

rule vsearch:
    input:
        fastx_uniques = rules.read_extension.output.out if is_activated("reads/extension") else rules.merge_lanes.output.fq,
    output:
        fastqout = temp("temp/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.fastq.gz"),
        log = "stats/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.log",
    log:
        "logs/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/derep/vsearch/{sample}_{library}_{read_type_trim}.tsv"
    params:
        extra = check_cmd(config["reads"]["derep"]["params"], forbidden_args = ["--fastx_uniques", "--fastqout", "--sizein", "--sizeout"]),
    threads: 1
    resources:
        mem = lambda w, attempt: f"{100 * attempt} GiB",
        runtime = lambda w, attempt: f"{5 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/vsearch"



rule seqkit:
    input:
        fastx = rules.read_extension.output if is_activated("reads/extension") else rules.merge_lanes.output.fq,
    output:
        fastx = temp("temp/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.fastq.gz"),
        # touch() needed, since file is not created if no dup reads
        dup_num = touch("stats/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.dup.tsv")
    log:
        "logs/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/derep/seqkit/{sample}_{library}_{read_type_trim}.tsv"
    params:
        command = "rmdup",
        extra = "--ignore-case --by-seq " + check_cmd(config["reads"]["derep"]["params"], forbidden_args = ["-j", "--threads", "-s", "--by-seq", "-i", "--ignore-case", "-D", "--dup-num-file", "-o", "--out-file"]),
    threads: 10
    resources:
        mem = lambda w, attempt: f"{100 * attempt} GiB",
        runtime = lambda w, attempt: f"{2 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/seqkit"
