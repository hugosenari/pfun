from hypothesis import given, assume

from tests.monad_test import MonadTest
from pfun import state, identity, compose
from tests.strategies import anything, unaries, states
from .utils import recursion_limit


class TestState(MonadTest):
    @given(anything(), anything())
    def test_right_identity_law(self, value, init_state):
        assert (
            state.wrap(value).and_then(
                state.wrap
            ).run(init_state) == state.wrap(value).run(init_state)
        )

    @given(unaries(states()), anything(), anything())
    def test_left_identity_law(self, f, value, init_state):
        assert (
            state.wrap(value).and_then(f).run(init_state) ==
            f(value).run(init_state)
        )

    @given(states(), unaries(states()), unaries(states()), anything())
    def test_associativity_law(self, s, f, g, init_state):
        assert (
            s.and_then(f).and_then(g).run(init_state) ==
            s.and_then(lambda x: f(x).and_then(g)).run(init_state)
        )

    @given(anything(), anything())
    def test_equality(self, value, init_state):
        assert state.wrap(value).run(init_state
                                     ) == state.wrap(value).run(init_state)

    @given(anything(), anything(), anything())
    def test_inequality(self, first, second, init_state):
        assume(first != second)
        assert state.wrap(first).run(init_state
                                     ) != state.wrap(second).run(init_state)

    @given(anything(), anything())
    def test_identity_law(self, value, init_state):
        assert (
            state.wrap(value).map(identity).run(init_state) ==
            state.wrap(value).run(init_state)
        )

    @given(unaries(), unaries(), anything(), anything())
    def test_composition_law(self, f, g, value, init_state):
        h = compose(f, g)
        assert (
            state.wrap(value).map(h).run(init_state) ==
            state.wrap(value).map(g).map(f).run(init_state)
        )

    def test_get(self):
        assert state.get().run('state') == ('state', 'state')

    def test_set(self):
        assert state.put('new_state').run('state') == (None, 'new_state')

    def test_with_effect(self):
        @state.with_effect
        def f():
            a = yield state.wrap(2)
            b = yield state.wrap(2)
            return a + b

        assert f().run(None) == (4, None)

        @state.with_effect
        def test_stack_safety():
            for _ in range(500):
                yield state.wrap(1)
            return None

        with recursion_limit(100):
            test_stack_safety().run(None)

    def test_sequence(self):
        assert state.sequence(state.wrap(v) for v in range(3)
                              ).run(None) == ((0, 1, 2), None)

    def test_stack_safety(self):
        with recursion_limit(100):
            state.sequence([state.wrap(v) for v in range(500)]).run(None)

    def test_filter_m(self):
        assert state.filter_m(lambda v: state.wrap(v % 2 == 0),
                              range(3)).run(None) == ((0, 2), None)

    def test_map_m(self):
        assert state.map_m(state.wrap, range(3)).run(None) == ((0, 1, 2), None)
