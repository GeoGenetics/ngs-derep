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
        "benchmarks/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.tsv",
    params:
        alg = "kmer",
        extra = "-F",
    threads: 2
    resources:
        mem = lambda w, attempt: f"{10 * attempt} GiB",
        runtime = lambda w, attempt: f"{1 * attempt} h",
    wrapper:
         wrapper_ver + "/bio/nonpareil/infer"


rule nonpareil_plot:
    input:
        npo = rules.nonpareil_infer.output.redund_sum,
    output:
        plot = "reports/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.pdf",
        model = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.RData",
        json = "stats/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.json",
    log:
        "logs/reads/nonpareil/{tool}/{sample}_{library}_{read_type_trim}.plot.log",
    params:
        enforce_consistency = True,
        star = 90,
        correction_factor = True,
        plot_observed = True,
        plot_model = True,
        plot_dispersion = "ci95",
        plot_diversity = True,
    localrule: True
    threads: 1
    resources:
        mem = lambda w, attempt: f"{5 * attempt} GiB",
        runtime = lambda w, attempt: f"{1 * attempt} h",
    wrapper:
        wrapper_ver + "/bio/nonpareil/plot"
