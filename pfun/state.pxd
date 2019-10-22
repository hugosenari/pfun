from .monad cimport Monad

cdef class State(Monad):
    cdef object run_s
    
    cdef object _run(self, object state)
    
    cdef State _map(self, object f)
    
    cdef State _and_then(self, f)

cdef State _wrap(object x)

cdef State _get()

cdef State _put(state)