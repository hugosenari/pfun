import random

import pytest

from pfun import identity, compose
from pfun.list import with_effect, sequence, filter_m, map_m, List, list_, wrap
from hypothesis.strategies import integers, lists as lists_
from hypothesis import given, assume
from .strategies import anything, unaries, lists
from .monad_test import MonadTest
from .monoid_test import MonoidTest
from .utils import recursion_limit


class TestList(MonadTest):
    @given(lists())
    def test_left_append_identity_law(self, l):
        assert list_() + l == l

    @given(lists_(anything()))
    def test_getitem(self, l):
        assume(l != [])
        assert l[0] == l[0]

    @given(lists())
    def test_right_append_identity_law(self, l):
        assert l + list_() == l

    @given(lists(), lists(), lists())
    def test_append_associativity_law(self, x, y, z):
        assert (x + y) + z == x + (y + z)

    @given(lists(), unaries(lists()), unaries(lists()))
    def test_associativity_law(self, l: List, f, g):
        #import ipdb; ipdb.set_trace()
        assert l.and_then(f).and_then(g) == l.and_then(
            lambda x: f(x).and_then(g)
        )

    @given(lists_(anything()))
    def test_equality(self, t):
        assert list_((t)) == list_((t))

    @given(unaries(), unaries(), lists())
    def test_composition_law(self, f, g, l):
        h = compose(f, g)
        assert l.map(h) == l.map(g).map(f)

    @given(lists())
    def test_identity_law(self, l):
        assert l.map(identity) == l

    @given(lists_(anything()), lists_(anything()))
    def test_inequality(self, first, second):
        assume(first != second)
        assert list_((first)) != list_((second))

    @given(anything(), unaries(lists()))
    def test_left_identity_law(self, v, f):
        assert list_([v]).and_then(f) == f(v)

    @given(lists())
    def test_right_identity_law(self, l):
        assert l.and_then(lambda v: list_([v])) == l

    @given(lists_(anything()))
    def test_filter(self, l):
        def p(v):
            return id(v) % 2 == 0

        assert list_(l).filter(p) == list_(filter(p, l))

    @given(lists_(integers()))
    def test_reduce(self, l):
        i = sum(l)
        assert list_(l).reduce(lambda a, b: a + b, 0) == i

    @given(lists(min_size=1), anything())
    def test_setitem(self, l, value):
        index = random.choice(range(len(l)))
        with pytest.raises(TypeError):
            l[index] = value

    @given(lists(min_size=1))
    def test_delitem(self, l):
        index = random.choice(range(len(l)))
        with pytest.raises(TypeError):
            del l[index]

    @given(lists(), lists_(anything()))
    def test_extend(self, l1, l2):
        assert l1.extend(l2) == l1 + l2

    @given(lists(), lists())
    def test_zip(self, l1, l2):
        assert list_(l1.zip(l2)) == list_(zip(l1, l2))

    def test_with_effect(self):
        @with_effect
        def f():
            a = yield wrap(2)
            b = yield wrap(2)
            return a + b

        assert f() == wrap(4)

        @with_effect
        def test_stack_safety():
            for _ in range(500):
                yield wrap(1)
            return None

        with recursion_limit(100):
            test_stack_safety()

    def test_sequence(self):
        assert sequence([wrap(v) for v in range(3)]) == wrap((0, 1, 2))

    def test_stack_safety(self):
        with recursion_limit(100):
            sequence([wrap(v) for v in range(500)])

    def test_filter_m(self):
        assert filter_m(lambda v: wrap(v % 2 == 0), range(3)) == wrap((0, 2))

    def test_map_m(self):
        assert map_m(wrap, range(3)) == wrap((0, 1, 2))
