from numba import types, njit, typed


@njit
def done(result):
    result = typed.Dict.empty(types.string, types.pyobject)
    result['result'] = result
