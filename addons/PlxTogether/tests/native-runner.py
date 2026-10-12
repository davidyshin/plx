"""Run fixtures with an existing Lua 5.3/5.4 shared library, without npm."""
import ctypes
import os
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
os.chdir(root)
lua = ctypes.CDLL(sys.argv[1])
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.luaL_loadfilex.restype = ctypes.c_int
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ssize_t, ctypes.c_void_p]
lua.lua_pcallk.restype = ctypes.c_int
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
if not state:
    raise RuntimeError("Cannot create Lua state")
def check(code):
    if code:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode("utf-8", errors="replace"))
try:
    lua.luaL_openlibs(state)
    for source in list((root / "addon" / "PlxTogether").glob("*.lua")) + list((root / "tests").glob("*.lua")):
        check(lua.luaL_loadfilex(state, str(source).encode(), None))
        lua.lua_settop(state, 0)
    print("Native Lua syntax checks passed.", flush=True)
    check(lua.luaL_loadfilex(state, b"tests/run.lua", None))
    check(lua.lua_pcallk(state, 0, 0, 0, 0, None))
finally:
    lua.lua_close(state)
