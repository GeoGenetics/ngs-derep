"""
Rule test code for unit testing of rules generated with Snakemake 9.11.6.
"""


import os
import sys
import shutil
import pytest
import tempfile
from pathlib import Path
from subprocess import check_output

sys.path.insert(0, os.path.dirname(__file__))


@pytest.mark.skip(reason="sequence order is not deterministic")
def test_extend_tadpole(conda_prefix):

    with tempfile.TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir) / "workdir"
        config_path = Path(".tests/unit/extend_tadpole/config")
        data_path = Path(".tests/unit/extend_tadpole/data")
        expected_path = Path(".tests/unit/extend_tadpole/expected")

        # Copy config to the temporary workdir.
        shutil.copytree(config_path, workdir)

        # Copy data to the temporary workdir.
        shutil.copytree(data_path, workdir, dirs_exist_ok=True)

        # Run the test job.
        check_output(
            [
                "python",
                "-m",
                "snakemake",
                "temp/reads/extend/tadpole/HD827sonic_1_lib1_collapsed.fastq.gz",
                "--snakefile",
                "../../workflow/Snakefile",
                "-f",
                "--notemp",
                "--show-failed-logs",
                "-j1",
                "--target-files-omit-workdir-adjustment",
                "--allowed-rules",
                "extend_tadpole",
                "--configfile",
                "config/config.yaml",
                "--software-deployment-method",
                "conda",
                "--directory",
                workdir,
                "--set-threads",
                "extend_tadpole=1",
                "--set-resources",
                "extend_tadpole:mem_mb=10000",
            ]
            + conda_prefix
        )

        # Check the output byte by byte using cmp/zmp/bzcmp/xzcmp.
        # To modify this behavior, you can inherit from common.OutputChecker in here
        # and overwrite the method `compare_files(generated_file, expected_file), 
        # also see common.py.
        import common
        common.OutputChecker(data_path, expected_path, workdir).check()
