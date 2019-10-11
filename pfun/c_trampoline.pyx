cdef class List:
    cpdef List append(self, object other):
        return Cons(other, self)
    
    def __repr__(self):
        return self._repr()

    cdef str _repr(self):
        cdef List l
        cdef str s
        l = self
        elems_repr = ''
        while not isinstance(l, Empty):
            elems_repr = str((<Cons>l).head) + ', ' + elems_repr
            l = (<Cons>l).tail
        s = s[:-2]
        s += ')'
        return s


cdef class Empty(List):
    pass


def list_(xs):
    return _list(xs)


cdef List _list(list xs):
    cdef List l
    l = Empty()
    for x in xs:
        l = l.append(x)
    return l


cdef class Cons(List):
    cdef object head
    cdef List tail

    def __cinit__(self, head, tail):
        self.head = head
        self.tail = tail


cdef class Trampoline:
    def and_then(self, f):
        return self._and_then(f)
    
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
        return AndThen(self, f)


cdef class Done(Trampoline):
    cdef object result

    def __cinit__(self, result):
        self.result = result

cdef class Call(Trampoline):
    cdef object thunk

    def __cinit__(self, thunk):
        self.thunk = thunk

cdef class AndThen(Trampoline):
    cdef Trampoline sub
    cdef object cont

    def __cinit__(self, sub, cont):
        self.sub = sub
        self.cont = cont

    cdef Trampoline _and_then(self, object f):
        return AndThen(
            self.sub,
            lambda x: Call(lambda: self.cont(x).and_then(f))  # type: ignore
        )

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
        return Reader(lambda context: Call(lambda: self.run_r(context).and_then(lambda v: Call(lambda: (<Reader>f(v)).run_r(context)))))


def wrap(value):
    return _wrap(value)

def ask():
    return _ask()

cdef Reader _ask():
    return Reader(lambda context: Done(context))

def sequence(readers):
    return _sequence(readers)


ctypedef Reader (*reducer)(Reader, Reader)

cdef Reader reduce(List l, reducer f, Reader init):
    cdef Reader r
    r = init
    while not isinstance(l, Empty):
        head = (<Cons>l).head
        tail = (<Cons>l).tail
        r = f(r, head)
        l = tail
    return r

cdef Reader combine(Reader r1, Reader r2):
    cdef List l
    cdef object e
    return r1.and_then(lambda l: r2.and_then(lambda e: _wrap((<List>l).append(e))))

cdef Reader _sequence(List readers):
    reader = _wrap(Empty())
    
    return reduce(
        readers, 
        combine,
        reader
    )


cdef Reader _wrap(object value):
    return Reader(lambda _: Done(value))