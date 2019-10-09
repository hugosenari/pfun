cdef class CTrampoline:
    cpdef double run(self) except *:
        print('hello')
        return 0.0
