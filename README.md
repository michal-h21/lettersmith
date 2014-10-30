Lettersmith is a simple, flexible static site generator, written in [Lua](http://lua.org).

WORK IN PROGRESS

Lettersmith is based on a simple idea: load files as tables. So this:

`example.md`:

```markdown
An example post
```

...Becomes this:

```lua
{
  relative_filepath = "example.md",
  contents = "An example post",
  date = "2014-10-17T01:25:59"
}
```

- The file contents will end up in the `contents` field.
- The `date` will be read from the file's modified date, but you can provide your own by adding a `date` field to the headmatter. Lettersmith will automatically normalize any reasonable date format you provide to an [ISO date](https://en.wikipedia.org/wiki/ISO_8601).

You can also add metadata to documents using a using a [YAML](yaml.org) headmatter block at the top of the file. So this:

```markdown
---
title: Example title
summary: My great summary
---
An example post
```

...Becomes this:

```lua
{
  relative_filepath = "example.md",
  title = "Example title",
  summary = "My great summary",
  contents = "An example post",
  date = "2014-10-17T01:25:59"
}
```

Any YAML properties you put in the block will show up on the table!

The function `lettersmith.docs(path)` takes a filepath and returns a list of these document tables:

```lua
{
  relative_filepath = "foo/x.md",
  contents = "...",
  date = "2014-10-17T01:25:59"
},
{
  relative_filepath = 'bar/y.md",
  contents = "...",
  date = "2014-10-17T01:25:59"
},
...
```

That's it! No fancy classes, no silly conventions, no magic. Just a convenient library for processing files with functions.

Creating a site is simple. Just create a new lua file. Call it anything you like.

```lua
local lettersmith = require("lettersmith")
local use_markdown = require("lettersmith.markdown")
local filter = require("streams").filter

-- Get docs list
local docs = lettersmith.docs("raw/")

-- Render markdown
docs = use_markdown(docs)

-- Create custom "plugin" to remove drafts.
-- It's just a standard filter function!
docs = filter(docs, function (doc)
  return not doc.draft
end)

-- Build files
lettersmith.build(docs, "out")
```


Plugins
-------

Extending Lettersmith with new functionality is easy. There are no fancy plugin conventions to learn, just modify the documents list!

Lettersmith comes with a few useful plugins out of the box:

* Render markdown posts with `lettersmith.markdown`
* Mustache templates with `lettersmith.mustache`
* Generate pretty permalinks with `lettersmith.permalinks`
* Add site metadata to posts with `lettersmith.meta`
* Hide draft posts with `lettersmith.drafts`
* Generate RSS feeds with `lettersmith.rss`

Of course, this is just a start. "Plugins" are really just functions that modify a list of tables. This makes Lettersmith simple. It also means it is extremely flexible. Lettersmith can be anything you want: a website builder, a blog, a documentation generation script... If you need to transform text files, this is an easy way to do it.


Creating new plugins
--------------------

Don't see the feature you want? No problem. Since your files are just a list of tables, writing new plugins is as easy as changing what shows up in the list.

The list that `lettersmith.docs` returns is a Lua generator function. That means your list of files can be infinitely large (or as large as your hard-drive can handle, anyway).

```lua
local docs = lettersmith.docs('raw/')
print(docs)
-- function: 0x7fc573700450
```

Just like a table, you can use `for` to loop over items inside. However, unlike a table, only one doc exists in memory at a time. This lets us load in massive numbers of files without a problem. The library `streams` gives you standard `map`, `filter`, `reduce` functions that will also return generators.

Fancy generators not your thing? Just use `streams.collect` to load all docs into a standard Lua table:

```lua
local docs = collect(lettersmith.docs('raw/'))

print(docs[1])
-- table: 0x7fc575100210

for i, doc in ipairs(docs) do
  print(doc.contents)
end
-- "..."
-- "..."
-- "..."
```


What's so great about static sites?
-----------------------------------

Why use Lettersmith?

- The most important reason: it's simple.
- Blazing-fast sites on cheap hosting. Run-of-the-mill servers like Apache and nginx can serve thousands of static files per second.
- You can't hack what doesn't exist. Static sites aren't prone to being hacked, because they're entirely static... there is no program to hack.
- Your data is in plain text. No databases to worry about, no export necessary. Want to take your data elsewhere? It's all there in text files.


Thoughts
--------

- The goal shoudl be to avoid magic. However, for users that do not have experience with Lua or programming, it would be great to have a one-step process for installing and using plugins, as well as configuration. It's best to think of this as a veneer or "UI" on top of a no-frills no-magic, explicit-over-implicit library.
- Future Mac app... how to dispay thumbnails and theme information? Could have an `auto_register(t)` function that takes a table and looks for by-convention fields like `t[info]` and `t[use]`. Plugins could opt in to exporting these fields.
- Plugins should be distributed via Luarocks or a standard package manager, rather than some bespoke solution.


License
-------

The MIT License (MIT)

Copyright &copy; 2014, Gordon Brander

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
- Neither the name "Lettersmith" nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
