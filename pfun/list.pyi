from typing import TypeVar, Generic, Union, Callable, Iterable, Tuple, Iterator

from .immutable import Immutable


A = TypeVar('A')
B = TypeVar('B')


class Empty(Immutable):
    def prepend(self, other: A) -> List[A]:
        ...

    def extend(self, other: List[A]) -> List[A]:
        ...

    def map(self, f: Callable[[A], B]) -> List[B]:
        ...

    def filter(self, f: Callable[[A], bool]) -> List[A]:
        ...

    def and_then(self, f: Callable[[A], List[B]]) -> List[B]:
        ...

    def zip(self, other: Iterable[B]) -> Iterator[Tuple[A, B]]:
        ...

    def __rpow__(self, other: A) -> List[A]:
        ...

    def __add__(self, other: List[A]) -> List[A]:
        ...

    def __len__(self) -> int:
        ...

    def __iter__(self) -> Iterator[A]:
        ...


class Element(Generic[A], Immutable):
    head: A
    tail: List[A]

    def prepend(self, other: A) -> List[A]:
        ...

    def extend(self, other: List[A]) -> List[A]:
        ...

    def map(self, f: Callable[[A], B]) -> List[B]:
        ...

    def filter(self, f: Callable[[A], bool]) -> List[A]:
        ...

    def and_then(self, f: Callable[[A], List[B]]) -> List[B]:
        ...

    def zip(self, other: Iterable[B]) -> Iterator[Tuple[A, B]]:
        ...

    def __rpow__(self, other: A) -> List[A]:
        ...

    def __add__(self, other: List[A]) -> List[A]:
        ...

    def __len__(self) -> int:
        ...

    def __iter__(self) -> Iterator[A]:
        ...


List = Union[Empty, Element[A]]


def list_of(*xs: A) -> List[A]:
    ...
