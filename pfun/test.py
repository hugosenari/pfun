from __future__ import annotations
from pfun.maybe import Maybes, with_effect


@with_effect
def f(a: int) -> Maybes[int, int]:
    ...


reveal_type(f)
