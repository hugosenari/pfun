from monad cimport Monad
from trampoline cimport Done, Call, Trampoline

cdef class IO(Monad):
    cdef object run_io

    def __cinit__(self, run_io):
        self.run_io = run_io
    
    def map(self, f):
        return self._map(f)
    
    def run(self):
        return self._run()
    
    cdef object _run(self):
        return (<Trampoline>self.run_io())._run()
    
    cdef IO _map(self, object f):
        return IO(lambda: Call(lambda: (<Trampoline>self.run_io())._map(f)))
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef IO _and_then(self, f):
        return IO(lambda: Call(lambda: (<Trampoline>self.run_io())._and_then(lambda v: Call(lambda: (<IO>f(v)).run_io()))))

def wrap(x):
    return _wrap(x)

cdef IO _wrap(object x):
    return IO(lambda: Done(x))


def read_str(path):
    def run():
        with open(path) as f:
            return Done(f.read())
    return IO(run)
