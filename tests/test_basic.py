import inspect
import tempfile
from pathlib import Path

import pyfst
import pytest


def make_basic(fn: str):
    values = {"a": 1, "aa": 2,  "bbbb": 3}
    nbytes = pyfst.write(fn, values.items())
    assert nbytes == 22
    return pyfst.load(fn)


def test_fuzzy_1(tmp_path: Path):
    fn = str(tmp_path / "foo.fst")

    fst = make_basic(fn)
    assert fst.fuzzy("a", 1) == [("a", 1), ("aa", 2)]


def test_prefix_1(tmp_path: Path):
    fn = str(tmp_path / "foo.fst")

    fst = make_basic(fn)
    assert fst.prefix("a") == [("a", 1), ("aa", 2)]
