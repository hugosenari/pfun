cdef class List:
    cdef int length

    cdef List _prepend(self, object other)
    cdef object _reduce(self, object f, object init)
    cdef object _reduce_r(self, object f, object init)
    cdef List _extend(self, List other)
    cdef List _map(self, object f)
    cdef List _and_then(self, object f)
    cdef List _filter(self, object f)
    cdef object _iter(self)
    cdef str _repr(self)


cdef class Empty(List):
    pass


cdef List _list(object xs)



cdef class Element(List):
    cdef readonly object head
    cdef readonly List tail
