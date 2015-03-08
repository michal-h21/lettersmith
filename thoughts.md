Thoughts, philosophy, approach
------------------------------

Programming approach: the goal should be to avoid magic. However, for users that do not have experience with Lua or programming, it would be great to have a one-step process for installing and using plugins, as well as configuration. It's best to think of this as a veneer or "UI" on top of a no-frills no-magic, explicit-over-implicit library.

Future Mac app... how to dispay thumbnails and theme information? Could have an `auto_register(t)` function that takes a table and looks for by-convention fields like `t[info]` and `t[use]`. Plugins could opt in to exporting these fields.

Plugins should be distributed via Luarocks, rather than some bespoke distribution system.

It would be great to foster a culture of "hack and learn".

- Lettersmith mac app should be a tool you can use without knowing anything about programming. At worst, a manifest file. At best, just click-to-configure.
- Modifying a theme should be something you can do with entry-level HTML and CSS chops.
- From there, writing Lettersmith and plugins as LuaLit could be a good way to introduce people to programming.


Ideas
-----

Here's a crazy idea: we bring in YAML because Jekyll made that standard. However,
Lua was a data language before it was a scripting language. What if we created
an alternative doc plugin that gave you full scripting power by running
headmatter through loadstring? Is this useful?

    ---
    date = "2015-03-02",
    now = os.time()
    ---

We could then use variables in the contents itself:

    The current time is {{now}}.

Can we box globals to prevent them from leaking into the Lettersmith namespace?


Notes
-----

Embedding Lua http://lua-users.org/wiki/BuildingLua
