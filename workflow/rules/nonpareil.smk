#############
### RULES ###
#############

rule nonpareil_infer:
    input:
        lambda w: expand("{path}/reads/{tool}/{sample}_{library}_{read_type_trim}.fastq.gz", path = "results" if w.tool == "low_complexity" else "temp", allow_missing=True),
    output:
        redund_sum = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.npo",
        redund_val = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.npa",
        mate_distr = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.npc",
        log = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.log",
    log:
        "logs/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.log",
    benchmark:
        "benchmarks/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.jsonl",
    params:
        alg = "kmer",
        extra = "-F",
    threads: 2
    resources:
        mem = lambda w, attempt: f"{7 * attempt} GiB",
        runtime = lambda w, attempt: f"{3 * attempt} h",
    wrapper:
         f"{wrapper_ver}/bio/nonpareil/infer"


rule nonpareil_plot:
    input:
        npo = rules.nonpareil_infer.output.redund_sum,
    output:
        pdf = "reports/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.pdf",
        tsv = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.tsv",
        json = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.json",
    log:
        "logs/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.plot.log",
#    params: # Needs nonpareil>3.5.5
#        extra = "--star 90 --dispersion ci95",
    localrule: True
    threads: 1
    resources:
        mem = lambda w, attempt: f"{5 * attempt} GiB",
        runtime = lambda w, attempt: f"{1 * attempt} h",
    wrapper:
        f"{wrapper_ver}/bio/nonpareil/plot"
