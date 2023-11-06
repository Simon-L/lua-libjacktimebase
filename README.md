# libjacktimebase

A basic jack timebase that supports other beat types!

#### Dependencies for the run target :
- LuaJIT
- Luarocks
    * Lua packages: penlight, nocurses and inspect
        
It's very easy to use the library with C or just LuaJIT without the required lua packages for the test.

# Building and running the test script:

`cmake -Bbuild  -DBUILD_SHARED_LIBS=ON && cmake --build build --target run`

