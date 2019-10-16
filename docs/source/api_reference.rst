API Reference
====
Maybe
-----
.. automodule:: pfun.maybe
    :members:

.. autoattribute:: pfun.maybe.Maybe
    :annotation: = typing.Union[Nothing, Just[A]]
    
    Type alias for maybe union type

.. autoattribute:: pfun.maybe.Maybes
    :annotation: = typing.Generator[Maybe[A], A, B]

    Type alias for generators yielding maybes

Either
------
.. automodule:: pfun.either
    :members:

.. autoattribute:: pfun.either.Either
    :annotation: = typing.Union[Left[B], Right[A]]

    Type alias for either union type

.. autoattribute:: pfun.either.Eithers
    :annotation: = typing.Generator[Either[A, B], B, C]

    Type alias for generators yielding eithers

Result
-----
.. autofunction:: pfun.result.result

.. autoclass:: pfun.result.Result
    :members:

Reader
------

.. automodule:: pfun.reader
    :members:

.. autoattribute:: pfun.reader.Readers
    :annotation: = typing.Generator[Reader[C, A], A, B]

    Type alias for generators yielding readers

Writer
------

.. automodule:: pfun.writer
    :members:
    :special-members:
    :exclude-members: __weakref__,__setattr__,__repr__


State
-----

.. automodule:: pfun.state
    :members:
    :special-members:
    :exclude-members: __weakref__,__setattr__,__repr__

IO
----

.. automodule:: pfun.io
    :members:
    :special-members:
    :exclude-members: __weakref__,__setattr__,__repr__

Trampoline
----------

.. automodule:: pfun.trampoline
    :members:
    :special-members:
    :exclude-members: __weakref__,__setattr__,__repr__


Cont
----

.. automodule:: pfun.cont
    :members:
    :special-members:
    :exclude-members: __weakref__,__setattr__,__repr__

Free
----
.. automodule:: pfun.free
    :members:
    :special-members:
    :exclude-members: __weakref__,__setattr__,__repr__


Immutable
---------

.. autoclass:: pfun.Immutable
    :members:


Dict
----
.. autoclass:: pfun.Dict
    :members:
    :special-members:
    :exclude-members: __weakref__,clear,__setitem__,__delitem__
List
----
.. autoclass:: pfun.List
    :members:
    :special-members:
    :exclude-members: __weakref__,clear,__setitem__,__delitem__

curry
-----
.. autofunction:: pfun.curry

compose
-------
.. autofunction:: pfun.compose

always
------
.. autofunction:: pfun.always

pipeline
--------
.. autofunction:: pfun.pipeline

identity
--------

.. autofunction:: pfun.identity


