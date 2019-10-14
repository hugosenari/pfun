from .list cimport List, _list, Empty, Element
from trampoline cimport Done, Call

cdef class Reader:
    cdef object run_r

    def run(self, context):
        return self._run(context)
    
    cdef object _run(self, object context):
        return self.run_r(context).run()

    def __cinit__(self, run_r):
        self.run_r = run_r
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef Reader _and_then(self, object f):
        return Reader.__new__(
            Reader,
            lambda context: Call(
                lambda: self.run_r(context).and_then(
                    lambda v: Call(lambda: (<Reader>f(v)).run_r(context))
                )
            )
        )

def wrap(value):
    return _wrap(value)

def ask():
    return _ask()

cdef Reader _ask():
    return Reader.__new__(Reader, lambda context: Done.__new__(Done, context))

def sequence(readers):
    return _sequence(readers)

cdef Reader _sequence(object readers):
    cdef List readers_

    if isinstance(readers, List):
        readers_ = readers
    else:
        readers_ = _list(readers)
    def combine(Reader r1, Reader r2):
        return r1.and_then(lambda l: r2.and_then(lambda e: _wrap((<List>l)._prepend(e))))

    return readers_._reduce_r(combine, _wrap(Empty()))


cdef Reader _wrap(object value):
    return Reader(lambda _: Done.__new__(Done, value))
