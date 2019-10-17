from functools import wraps
from typing import Generator
import sys

from .curry import curry
from .monad cimport (
    Monad, 
    _sequence, 
    _map_m, 
    _filter_m, 
    wrap_t, 
    _with_effect
)
from .trampoline cimport Done, Call, Trampoline

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

def read_bytes(path):
    def run():
        with open(path, 'rb') as f:
            return Done(f.read())
    return IO(run) 

@curry
def write_str(path, content, mode='w'):
    def run():
        with open(path, mode) as f:
            f.write(content)
        return Done(None)
    return IO(run)

@curry
def write_bytes(path, content, mode='w'):
    def run():
        with open(path, mode + 'b') as f:
            f.write(content)
        return Done(None)
    return IO(run)

def get_line(prompt=''):
    def run():
        line = input(prompt)
        return Done(line)
    return IO(run)

@curry
def put_line(line='', file=sys.stdout):
    def run():
        print(line, file=file)
        return Done(None)
    return IO(run)

def sequence(maybes):
    return _sequence(<wrap_t>_wrap, maybes)

def map_m(f, iterable):
    return _map_m(<wrap_t>_wrap, f, iterable)

def filter_m(f, iterable):
    return _filter_m(<wrap_t>_wrap, f, iterable)

# hack to make it possible to
# import the type alias from .pyi
IOs = Generator

def with_effect(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect(<wrap_t>_wrap, g)
    return decorator