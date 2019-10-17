from .monad cimport Monad
from .trampoline cimport Trampoline, Call, Done

cdef class State(Monad):
    cdef object run_s

    def __cinit__(self, run_s):
        self.run_s = run_s
    
    def map(self, f):
        return self._map(f)
    
    def run(self, state):
        return self._run(state)
    
    cdef object _run(self, object state):
        return (<Trampoline>self.run_io(state))._run()
    
    cdef State _map(self, object f):
        return State(lambda s: Call(lambda: (<Trampoline>self.run_s(s))._map(f)))
    
    def and_then(self, f):
        return self._and_then(f)
    
    cdef State _and_then(self, f):
        return State(lambda s: 
            Call(lambda: 
                (<Trampoline>self.run_io(s))._and_then(lambda vs: 
                    Call(lambda: 
                        (<State>f(vs[0])).run_s(vs[1])
                    )
                )
            )
        )

def wrap(x):
    return _wrap(x)

cdef State _wrap(object x):
    return State(lambda s: Done((x, s)))

def get():
    return _get()

cdef State _get():
    return State(lambda s: Done(s, s))

def put(state):
    return _put(state)

cdef State _put(state):
    return State(lambda s: Done(None, state))
