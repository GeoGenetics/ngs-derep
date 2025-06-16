import pandas as pd
from typing import List


#################
### FUNCTIONS ###
#################

### General


def expand_pd(string: List, df: pd.DataFrame, allow_missing=False) -> List:
    return set(expand(string, zip, **df.to_dict("list"), allow_missing=allow_missing))


### Config


def is_activated(xpath):
    c = config
    for entry in xpath.split("/"):
        c = c.get(entry, {})
    return bool(c.get("activate", False))
