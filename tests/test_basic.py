import tempfile
import pyfst
from pathlib import Path
import inspect

def test_1(tmp_path: Path):
    fn = str(tmp_path / "foo.fst")
    
    values = {"a": 1, "aa": 2,  "bbbb": 3}
    nbytes = pyfst.write(fn, values.items())
    assert nbytes == 22
    
    qq = pyfst.load(fn)
    assert qq.fuzzy("a", 1) == [("a", 1), ("aa", 2)]
