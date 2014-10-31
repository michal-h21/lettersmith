Thoughts, philosophy, approach
------------------------------

Programming approach: the goal should be to avoid magic. However, for users that do not have experience with Lua or programming, it would be great to have a one-step process for installing and using plugins, as well as configuration. It's best to think of this as a veneer or "UI" on top of a no-frills no-magic, explicit-over-implicit library.

Future Mac app... how to dispay thumbnails and theme information? Could have an `auto_register(t)` function that takes a table and looks for by-convention fields like `t[info]` and `t[use]`. Plugins could opt in to exporting these fields.

Plugins should be distributed via Luarocks, rather than some bespoke distribution system.

It would be great to foster a culture of "hack and learn".

- Lettersmith mac app should be a tool you can use without knowing anything about programming. At worst, a manifest file. At best, just click-to-configure.
- Modifying a theme should be something you can do with entry-level HTML and CSS chops.
- From there, writing Lettersmith and plugins as LuaLit could be a good way to introduce people to programming.


Notes
-----

Embedding Lua http://lua-users.org/wiki/BuildingLua
