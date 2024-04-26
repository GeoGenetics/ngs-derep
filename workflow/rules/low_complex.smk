
def _get_results():
    if is_activated("reads/extension") and is_activated("reads/derep"):
        return expand(rules.seqkit_grep.output.fastx, tool=config["reads"]["derep"]["tool"], allow_missing=True)
    elif not is_activated("reads/extension") and is_activated("reads/derep"):
        return expand("temp/reads/derep/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz", tool=config["reads"]["derep"]["tool"], allow_missing=True)
    elif is_activated("reads/extension") and not is_activated("reads/derep"):
        return rules.read_extension.output.out
    else:
        return rules.merge_lanes.output



#############
### RULES ###
#############

rule low_complexity:
    input:
        _get_results(),
    output:
        out = "results/reads/low_complexity/{sample}_{library}_{read_type_trim}.fastq.gz",
        outmatch = temp("temp/reads/low_complexity/{sample}_{library}_{read_type_trim}.discarded.fastq.gz"),
        stats = "stats/reads/low_complexity/{sample}_{library}_{read_type_trim}.txt"
    log:
        "logs/reads/low_complexity/{sample}_{library}_{read_type_trim}.log"
    benchmark:
        "benchmarks/reads/low_complexity/{sample}_{library}_{read_type_trim}.jsonl"
    params:
        command="bbduk.sh",
        extra=check_cmd(config["reads"]["low_complex"]["params"]),
        ref=["adapters", "artifacts"],
    threads: 4
    resources:
        mem = lambda w, attempt: f"{4 * attempt} GiB",
        runtime = lambda w, attempt: f"{2 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/bbtools"
