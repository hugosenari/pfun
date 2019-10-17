from functools import wraps
from typing import Generator

from .list cimport List, _list, Empty, Element
from .trampoline cimport Done, Call, Trampoline
from .monad cimport (
    _sequence as _sequence_, 
    _map_m as _map_m_, 
    Monad, wrap_t, 
    _filter_m as 
    _filter_m_, 
    _with_effect as 
    _with_effect_
)

cdef class Reader(Monad):
    """
    Represents a computation that is not yet completed, but
    will complete once given an object of type ``Context``
    """
    cdef object run_r

    def __cinit__(self, run_r):
        self.run_r = run_r

    def run(self, context):
        """
        Apply this :class:`Reader` to the ``context``

        :example:
        >>> value(1).run(...)
        1
        
        :type context: C
        :param c: The context to passed to the
                  function wrapped by this :class:`Reader`
        :return: The result of this :class:`Reader`
        :rtype: A
        """
        return self._run(context)
    
    cdef object _run(self, object context):
        return (<Trampoline>self.run_r(context))._run()
    
    def and_then(self, f):
        """
        Compose ``f`` with the function wrapped by this
        :class:`Reader` instance
        
        :example:
        >>> ask().and_then(
        ...     lambda context: value(f'context: {context}')
        ... ).run([])
        'context: []'

        :type f: Callable[[A], [Reader[C, B]]]
        :param f: Function to compose with this this :class:`Reader`
        :return: Composed :class:`Reader`
        :rtype: Reader[C, B]
        """
        return self._and_then(f)
    
    def map(self, f):
        """
        Apply ``f`` to the result of this :class:`Reader`
        :example:
        >>> value(1).map(str).run(...)
        '1'

        :type f: Callable[[A], B]
        :param f: Function to apply
        :return: :class:`Reader` that returns the result of
                 applying ``f`` to its result
        :rtype: Reader[C, B]
        """
        return self._map(f)
    
    cdef Reader _map(self, object f):
        return Reader(lambda context: Call(lambda: (<Trampoline>self.run_r(context))._map(f)))
    
    cdef Reader _and_then(self, object f):
        return Reader.__new__(
            Reader,
            lambda context: Call(
                lambda: (<Trampoline>self.run_r(context))._and_then(
                    lambda v: Call(lambda: (<Reader>f(v)).run_r(context))
                )
            )
        )

def wrap(value):
    """
    Make a ``Reader`` that will produce ``value`` no matter the context
    
    :example:
    >>> wrap(1).run(None)
    1

    :type value: A
    :param value: the value to put in a :class:`Reader` instance
    :return: :class:`Reader` that returns ``v`` when given any context
    :rtype: Reader[C, A]
    """
    return _wrap(value)

def ask():
    """
    Make a :class:`Reader` that just returns the context.

    :example:
    >>> ask().run('Context')
    'Context'

    :return: :class:`Reader` that will return the context when run
    :rtype: Reader[C, C]
    """
    return _ask()

cdef Reader _ask():
    return Reader.__new__(Reader, lambda context: Done.__new__(Done, context))


def reader(f):
    """
    Wrap any function in a :class:`Reader` context.
    Useful for making non-monadic
    functions monadic. Can also be used as a decorator
    
    :example:
    >>> to_int = reader(int)
    >>> to_int('1').and_then(lambda i: i + 1).run(...)
    2

    :type f: Callable[..., A]
    :param f: Function to wrap
    :return: Wrapped function
    :rtype: Callable[..., Reader[C, A]]
    """
    @wraps(f)
    def decorator(*args, **kwargs):
        return wrap(f(*args, **kwargs))
    return decorator

def sequence(readers):
    """
    Evaluate each :class:`Reader` in `iterable` from left to right
    and collect the results
    
    :example:
    >>> sequence([wrap(v) for v in range(3)]).run(...)
    (0, 1, 2)

    :type readers: Iterable[Reader[C, A]]
    :param iterable: The iterable to collect results from
    :returns: :class:`Reader` of collected results
    :rtype: Reader[C, Tuple[A]]
    """
    return _sequence(readers)

cdef Reader _sequence(object readers):
    return _sequence_(<wrap_t>_wrap, readers)

def map_m(f, iterable):
    """
    Map each in element in ``iterable`` to
    a :class:`Reader` by applying ``f``,
    combine the elements by ``and_then``
    from left to right and collect the results
    
    :example:
    >>> map_m(wrap, range(3)).run(...)
    (0, 1, 2)
    
    :type f: Callable[[A], Reader[C, B]]
    :param f: Function to map over ``iterable``
    :type iterable: Iterable[A]
    :param iterable: Iterable to map ``f`` over
    :return: ``f`` mapped over ``iterable`` and combined from left to right
    :rtype: Reader[C, Tuple[B]]
    """
    return _map_m(f, iterable)

cdef Reader _map_m(object f, object xs):
    return _map_m_(<wrap_t>_wrap, f, xs)

def filter_m(f, iterable):
    """
    Map each element in ``iterable`` by applying ``f``,
    filter the results by the value returned by ``f``
    and combine from left to right.
    
    :example:
    >>> filter_m(lambda v: wrap(v % 2 == 0), range(3)).run(...)
    (0, 2)
    
    :type f: Callable[[A], Reader[C, bool]]
    :param f: Function to map ``iterable`` by
    :type iterable: Iterable[A]
    :param iterable: Iterable to map by ``f``
    :return: `iterable` mapped and filtered by `f`
    :rtype: Reader[C, Tuple[A]]
    """
    return _filter_m(f, iterable)

cdef Reader _filter_m(object f, object xs):
    return _filter_m_(<wrap_t>_wrap, f, xs)

Readers = Generator

def with_effect(f):
    """
    Decorator for functions that
    return a generator of readers and a final result.
    Iteraters over the yielded readers and sends back the
    unwrapped values using "and_then"
    :example:
    >>> @with_effect
    ... def f() -> Readers[Any, int, int]:
    ...     a = yield wrap(2)
    ...     b = yield wrap(2)
    ...     return a + b
    >>> f().run(None)
    4

    :type f: Callable[..., Readers[C, A, B]]
    :param f: generator function to decorate
    :return: `f` decorated such that generated :class:`Maybe` \
        will be chained together with `and_then`
    :rtype: Callable[..., Reader[C, B]]
    """
    @wraps(f)
    def decorator(*args, **kwargs):
        g = f(*args, **kwargs)
        return _with_effect_(<wrap_t>_wrap, g)
    return decorator

cdef Reader _wrap(object value):
    return Reader(lambda _: Done.__new__(Done, value))
