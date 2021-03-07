extern crate anyhow;
extern crate fst;
extern crate memmap;
extern crate pyo3;

use anyhow::Error;
use fst::automaton;
use fst::map::MapBuilder;
use fst::raw::Fst;
use fst::Automaton;
use fst::{IntoStreamer, Streamer};
use memmap::Mmap;
use pyo3::exceptions::*;
use pyo3::prelude::*;
use pyo3::types::PyIterator;
use pyo3::wrap_pyfunction;
use std::fs::File;
use std::io;
use std::path::Path;

pub unsafe fn mmap_fst<P: AsRef<Path>>(path: P) -> Result<Fst<Mmap>, Error> {
    let mmap = Mmap::map(&File::open(path)?)?;
    let fst = Fst::new(mmap)?;
    Ok(fst)
}

#[pyclass]
pub struct PyFst {
    handle: Fst<Mmap>,
}

#[pymethods]
impl PyFst {
    #[new]
    fn new(db: &str) -> PyResult<Self> {
        let fst = unsafe { mmap_fst(db) }.map_err(|e| PyOSError::new_err(e.to_string()))?;
        Ok(PyFst { handle: fst })
    }

    /// fuzzy(query, distance, /)
    /// --
    ///
    /// Levenshtein (edit-distance) search
    fn fuzzy(&self, query: &str, distance: u32) -> PyResult<Vec<(String, u64)>> {
        let lev = automaton::Levenshtein::new(query, distance)
            .map_err(|e| PyOSError::new_err(e.to_string()))?;
        let mut stream = self.handle.search(lev).into_stream();
        let mut kvs = vec![];
        while let Some((k, v)) = stream.next() {
            let ks = std::str::from_utf8(k)?.to_string();
            let vs = v.value();
            kvs.push((ks, vs));
        }
        Ok(kvs)
    }

    /// prefix(query, /)
    /// --
    ///
    /// Search by prefix
    fn prefix(&self, query: &str) -> PyResult<Vec<(String, u64)>> {
        let matcher = automaton::Str::new(query).starts_with();
        let mut stream = self.handle.search(matcher).into_stream();

        let mut kvs = vec![];
        while let Some((k, v)) = stream.next() {
            let ks = std::str::from_utf8(k)?.to_string();
            let vs = v.value();
            kvs.push((ks, vs));
        }
        Ok(kvs)
    }
}

/// write(db: str, items: Iterable[Tuple[str, int]], /)
/// --
///
/// Create a FST on disk, at location `db`, with contents from
/// `items`.
#[pyfunction]
pub fn write<'p>(py: Python<'p>, db: PyObject, it: PyObject) -> PyResult<u64> {
    let path: String = db.extract(py)?;
    let wtr = io::BufWriter::new(File::create(path)?);
    let mut map = MapBuilder::new(wtr).map_err(|e| PyOSError::new_err(e.to_string()))?;

    let iterator = PyIterator::from_object(py, &it)?;
    let kv_pairs = iterator.map(|x| x.and_then(PyAny::extract::<(String, u64)>));

    for row in kv_pairs {
        let (key, value) = row?;
        map.insert(key, value)
            .map_err(|e| PyOSError::new_err(e.to_string()))?;
    }
    let nbytes = map.bytes_written();
    map.finish()
        .map_err(|e| PyOSError::new_err(e.to_string()))?;
    Ok(nbytes)
}

/// load(db: str, /)
/// --
///
/// Load a FST map from disk.
#[pyfunction]
pub fn load<'p>(py: Python<'p>, db: PyObject) -> PyResult<PyFst> {
    let path: String = db.extract(py)?;
    PyFst::new(&path)
}

#[pymodule]
pub fn pyfst(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_class::<PyFst>()?;
    m.add_wrapped(wrap_pyfunction!(write)).unwrap();
    m.add_wrapped(wrap_pyfunction!(load)).unwrap();
    Ok(())
}
