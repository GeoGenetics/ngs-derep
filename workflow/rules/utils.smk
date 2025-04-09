import pandas as pd
from typing import List, Dict


#################
### FUNCTIONS ###
#################

### General


def expand_pandas(string: List, df: pd.DataFrame, allow_missing=False) -> List:
    """Expand string following columns in the dataframe"""
    return set(
        flatten(
            [
                expand(string, **row._asdict(), allow_missing=allow_missing)
                for row in df.itertuples(False)
            ]
        )
    )


### Config


def _item_or_sample(row, item):
    i = getattr(row, item, None)
    if pd.isnull(i):
        return getattr(row, "sample")
    return i


def is_activated(xpath):
    c = config
    for entry in xpath.split("/"):
        c = c.get(entry, {})
    return bool(c.get("activate", False))
