import cffi

ffi = cffi.FFI()

ffi.cdef(
    """
    typedef struct {
        int done;
        struct Trampoline (*thunk)();
    } Trampoline;
"""
)

ffi.set_source(
    "_trampoline",
    """
    int run(Trampoline* trampoline) {
        while (&trampoline.done == NULL) {
            trampoline = &trampoline.thunk()
        }
        return &trampoline.done;
    }
    """
)

ffi.compile()


def done(result: int):
    return ffi.new(
        "struct Trampoline *", {
            "result": result, "thunk": ffi.NULL
        }
    )


def call(thunk):
    return ffi.new("struct Trampoline *", {"result": ffi.NULL, "thunk": thunk})
