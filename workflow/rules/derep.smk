#############
### RULES ###
#############

if config["derep"]["tool"] == "vsearch":

    rule vsearch:
        input:
            fastx_uniques=(
                rules.extend_tadpole.output.out
                if is_activated("extension")
                else rules.merge_lanes.output.fq
            ),
        output:
	    # NOTE: Base Qualities if output FASTQ file are not the same as in the input read. They are either an average or the maximum value.
            fastqout=temp(
                "<temp>/reads/derep/{sample}_{library}_{read_type_trim}.fastq.gz"
            ),
        log:
            "<logs>/reads/derep/{sample}_{library}_{read_type_trim}.log",
        benchmark:
            "<benchmarks>/reads/derep/{sample}_{library}_{read_type_trim}.jsonl"
        priority: 10
        threads: 1
        resources:
            mem=lambda w, attempt: f"{100* attempt} GiB",
            runtime=lambda w, attempt: f"{5* attempt} h",
        params:
            extra=config["derep"]["params"],
        wrapper:
            "v9.18.1/bio/vsearch"

elif config["derep"]["tool"] == "seqkit":

    rule seqkit:
        input:
            fastx=(
                rules.extend_tadpole.output
                if is_activated("extension")
                else rules.merge_lanes.output.fq
            ),
        output:
            fastx=temp(
                "<temp>/reads/derep/{sample}_{library}_{read_type_trim}.fastq.gz"
            ),
            # touch() needed, since file is not created if no dup reads
            dup_num=touch(
                "<stats>/reads/derep/{sample}_{library}_{read_type_trim}.dup.tsv"
            ),
        log:
            "<logs>/reads/derep/{sample}_{library}_{read_type_trim}.log",
        benchmark:
            "<benchmarks>/reads/derep/{sample}_{library}_{read_type_trim}.jsonl"
        priority: 10
        threads: 4
        resources:
            mem=lambda w, input, attempt: f"{(8* input.size_gb+50)* attempt} GiB",
            runtime=lambda w, input, attempt: f"{(0.08* input.size_gb+0.5)* attempt} h",
        params:
            command="rmdup",
            extra="--ignore-case --by-seq " + config["derep"]["params"],
        wrapper:
            "v9.19.5/bio/seqkit"

elif config["derep"]["tool"] == "swarm":

    rule swarm_vsearch:
        input:
            fastx_uniques=(
                rules.extend_tadpole.output.out
                if is_activated("extension")
                else rules.merge_lanes.output.fq
            ),
        output:
            fastaout=temp(
                "<temp>/reads/derep/swarm_vsearch/{sample}_{library}_{read_type_trim}.fasta.gz"
            ),
        log:
            "<logs>/reads/derep/swarm_vsearch/{sample}_{library}_{read_type_trim}.log",
        benchmark:
            "<benchmarks>/reads/derep/swarm_vsearch/{sample}_{library}_{read_type_trim}.jsonl"
        priority: 10
        threads: 1
        resources:
            mem=lambda w, attempt: f"{100* attempt} GiB",
            runtime=lambda w, attempt: f"{5* attempt} h",
        params:
            extra="--strand both --sizeout --fasta_width 0",
        wrapper:
            "v9.18.1/bio/vsearch"

    rule swarm_vsearch_N:
        input:
            fastx_filter=rules.swarm_vsearch.output.fastaout,
        output:
            fastaout=temp(
                "<temp>/reads/derep/swarm_vsearch_N/{sample}_{library}_{read_type_trim}.fasta.gz"
            ),
        log:
            "<logs>/reads/derep/swarm_vsearch_N/{sample}_{library}_{read_type_trim}.log",
        benchmark:
            "<benchmarks>/reads/derep/swarm_vsearch_N/{sample}_{library}_{read_type_trim}.jsonl"
        priority: 10
        threads: 1
        resources:
            mem=lambda w, attempt: f"{10* attempt} GiB",
            runtime=lambda w, attempt: f"{1* attempt} h",
        params:
            extra="--fastq_maxns 0",
        wrapper:
            "v9.18.1/bio/vsearch"

    rule swarm:
        input:
            rules.swarm_vsearch_N.output.fastaout,
        output:
            output=temp("<temp>/reads/derep/swarm/{sample}_{library}_{read_type_trim}.clusters"),
            statistics="<stats>/reads/derep/swarm/{sample}_{library}_{read_type_trim}.stats.tsv",
        log:
            "<logs>/reads/derep/swarm/{sample}_{library}_{read_type_trim}.log",
        benchmark:
            "<benchmarks>/reads/derep/swarm/{sample}_{library}_{read_type_trim}.jsonl"
        priority: 10
        threads: 10
        resources:
            mem=lambda w, attempt: f"{100* attempt} GiB",
            runtime=lambda w, attempt: f"{5* attempt} h",
        params:
            extra="--usearch-abundance " + config["derep"]["params"],
        wrapper:
            "v9.15.0/bio/swarm"

    rule swarm_fix_read_ids:
        input:
            rules.swarm.output.output,
        output:
            temp(
                "<temp>/reads/derep/swarm/fix_read_ids/{sample}_{library}_{read_type_trim}.tsv"
            ),
        log:
            "<logs>/reads/derep/swarm/fix_read_ids/{sample}_{library}_{read_type_trim}.log",
        priority: 10
        localrule: True
        threads: 10
        resources:
            mem=lambda w, attempt: f"{1* attempt} GiB",
            runtime=lambda w, attempt: f"{10* attempt} m",
        params:
            expr=r"s/;size=[0-9]+.*//",
            extra="-r",
        wrapper:
            "v9.8.0/utils/sed"

    rule swarm_grep:
        input:
            fastx=rules.swarm_vsearch.input.fastx_uniques,
            pattern=rules.swarm_fix_read_ids.output[0],
        output:
            fastx=temp(
                "<temp>/reads/derep/{sample}_{library}_{read_type_trim}.fastq.gz"
            ),
        log:
            "<logs>/reads/derep/{sample}_{library}_{read_type_trim}.log",
        benchmark:
            "<benchmarks>/reads/derep/{sample}_{library}_{read_type_trim}.jsonl"
        priority: 10
        threads: 10
        resources:
            mem=lambda w, attempt: f"{10* attempt} GiB",
            runtime=lambda w, attempt: f"{30* attempt} m",
        params:
            command="grep",
            extra="--delete-matched",
        wrapper:
            "v9.19.5/bio/seqkit"
