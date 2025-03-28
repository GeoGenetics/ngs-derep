def _get_results():
    if is_activated("reads/extension") and is_activated("reads/derep"):
        return rules.seqkit_grep.output.fastx
    elif not is_activated("reads/extension") and is_activated("reads/derep"):
        return "temp/reads/derep/{sample}_{library}_{read_type_trim}.fastq.gz"
    elif is_activated("reads/extension") and not is_activated("reads/derep"):
        return rules.extend_tadpole.output.out
    else:
        return rules.merge_lanes.output


#############
### RULES ###
#############


rule low_complexity:
    input:
        _get_results(),
    output:
        out="results/reads/low_complexity/{sample}_{library}_{read_type_trim}.fastq.gz",
        outmatch=temp(
            "temp/reads/low_complexity/{sample}_{library}_{read_type_trim}.discarded.fastq.gz"
        ),
        stats="stats/reads/low_complexity/{sample}_{library}_{read_type_trim}.txt",
    log:
        "logs/reads/low_complexity/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/low_complexity/{sample}_{library}_{read_type_trim}.jsonl"
    params:
        command="bbduk.sh",
        extra=config["reads"]["low_complex"]["params"],
        ref=["adapters", "artifacts"],
    priority: 10
    threads: 4
    resources:
        mem=lambda w, attempt: f"{4* attempt} GiB",
        runtime=lambda w, attempt: f"{2* attempt} h",
    wrapper:
        f"{wrapper_ver}/bio/bbtools"
