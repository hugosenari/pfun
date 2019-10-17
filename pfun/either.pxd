from .monad cimport Monad


cdef class _Either(Monad):
    pass


cdef class Right(_Either):
    cdef readonly object get
    
    cdef _Either _map(self, object f)    
    cdef _Either _and_then(self, object f)


cdef class Left(_Either):
    cdef readonly object get
    
    cdef _Either _map(self, object f)
    cdef _Either _and_then(self, object f)