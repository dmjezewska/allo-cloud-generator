# Alloverse app template

This is an Alloverse app. You can
[read about making apps](https://docs.alloverse.com/) here.

**psst, you should summarize and explain your project here!**

## Developing

Application sources are in `lua/`.

To start the app and connect it to an Alloplace for testing, run

```
./allo/assist run alloplace://nevyn.places.alloverse.com
```

## Documentation

We've published an early version of a [comprehensive documentation website](https://docs.alloverse.com/), though it's not exhaustive yet. Additional documentation
is provided in your `lua/main.lua`.

The implementation of the [UI library](https://docs.alloverse.com/classes/) also has some documentation inline which you can use while we're
improving the docs website. Navigate to `allo/deps/alloui/lua/alloui` and have a look at the various
lua files in there, and in particular the various UI elements under `views`. Some various views include:

- Surface, a flat surface to put stuff on
- Label, for displaying text
- Button, for clicking on
- Navstack, for drilling into nested data
