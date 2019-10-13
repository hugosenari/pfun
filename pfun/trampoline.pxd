cdef class Trampoline:
    cdef object _run(self)
    cdef Trampoline _map(self, object f)
    cdef Trampoline _and_then(self, object f)


cdef class Done(Trampoline):
    cdef object result

cdef class Call(Trampoline):
    cdef object thunk

cdef class AndThen(Trampoline):
    cdef Trampoline sub
    cdef object cont

    cdef object _run(self)

    cdef Trampoline _and_then(self, object f)
