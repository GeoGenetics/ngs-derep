#!/bin/bash

SNAKEMAKE_OPTS="--snakefile ../../workflow/Snakefile --configfile config/config.yaml --printshellcmds --software-deployment-method conda --conda-prefix /tmp/cache/conda $@"

for TEST in robot_tests_all robot_tests_extend robot_tests_derep robot_tests_none
do
    cd $TEST/
    snakemake $SNAKEMAKE_OPTS --dryrun
    snakemake $SNAKEMAKE_OPTS --rulegraph | dot -Tsvg > rulegraph.svg
    snakemake $SNAKEMAKE_OPTS --filegraph | dot -Tsvg > filegraph.svg
    snakemake $SNAKEMAKE_OPTS --dag | dot -Tsvg > dag.svg
    cd ../
done
