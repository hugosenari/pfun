from monad cimport Monad


cdef class Either(Monad):
    pass


cdef class Right(Either):
    cdef readonly object get
    
    cdef Either _map(self, object f)    
    cdef Either _and_then(self, object f)


cdef class Left(Either):
    cdef readonly object get
    
    cdef Either _map(self, object f)
    cdef Either _and_then(self, object f)