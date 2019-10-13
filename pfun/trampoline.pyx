cdef class Trampoline:
    def and_then(self, f):
        return self._and_then(f)
    
    def map(self, f):
        return self._map(f)
    
    cdef Trampoline _map(self, object f):
        return self._and_then(lambda v: Done(f(v)))
    
    def run(self):
        return self._run()
    
    cdef object _run(self):
        cdef Trampoline trampoline
        trampoline = self
        while not isinstance(trampoline, Done):
            if isinstance(trampoline, Call):
                trampoline = (<Call>trampoline).thunk()
            else:
                sub1 = (<AndThen>trampoline).sub
                cont1 = (<AndThen>trampoline).cont
                if isinstance(sub1, Done):
                    trampoline = cont1((<Done>sub1).result)
                elif isinstance(sub1, Call):
                    trampoline = (<Call>sub1).thunk().and_then(cont1)
                else:
                    sub2 = (<AndThen>sub1).sub
                    cont2 = (<AndThen>sub1).cont
                    trampoline = sub2.and_then(cont2).and_then(cont1)
        return (<Done>trampoline).result


    cdef Trampoline _and_then(self, object f):
        return AndThen.__new__(AndThen, self, f)


cdef class Done(Trampoline):
    def __cinit__(self, result):
        self.result = result

cdef class Call(Trampoline):
    def __cinit__(self, thunk):
        self.thunk = thunk

cdef class AndThen(Trampoline):
    def __cinit__(self, sub, cont):
        self.sub = sub
        self.cont = cont

    cdef Trampoline _and_then(self, object f):
        return AndThen.__new__(
            AndThen,
            self.sub,
            lambda x: Call(lambda: self.cont(x).and_then(f))  # type: ignore
        )
