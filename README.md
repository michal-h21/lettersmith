Lettersmith
===========

Lettersmith is a simple, flexible, fast  _static site generator_. It's written in [Lua](http://lua.org).

Lettersmith's goals are:

- Simple: no fancy classes, no silly conventions. Just a minimal library for transforming files with functions.
- Flexible: everything is a plugin.
- Fast: build thousands of pages in seconds or less.
- Embeddable: we're going to put this thing in an Mac app so normal people can use it.

Lettersmith is open-source and a work-in-progress. [You can help](https://github.com/gordonbrander/lettersmith/issues).


What does it do?
----------------

Lettersmith is built around a simple idea: load files as Lua tables. So this:

`example.md`:

```markdown
---
title: Trying out Lettersmith
---
Let's add some content to this file.
```

...Becomes this:

```lua
{
  relative_filepath = "example.md",
  title = "Trying out Lettersmith",
  contents = "Let's add some content to this file.",
  date = "2014-10-17T01:25:59"
}
```

- The file contents will end up in the `contents` field.
- You can add an optional [YAML](yaml.org) headmatter block to files. Any YAML properties you put in the block will show up on the table!
- The `date` will be read from the file's modified date, but you can provide your own by adding a `date` field to the headmatter. Lettersmith will automatically normalize any reasonable date format you provide to an [ISO date](https://en.wikipedia.org/wiki/ISO_8601).

The function `lettersmith.docs(path)` takes a file path and returns a list of document objects:

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

Creating a site is simple. Just create a new lua file. Call it anything you like.

```lua
local lettersmith = require("lettersmith")
local use_markdown = require("lettersmith.markdown")

-- Get documents from "raw" folder
local docs = lettersmith.docs("raw")

-- Render markdown
docs = use_markdown(docs)

-- Build files, writing them to "out" folder
lettersmith.build(docs, "out")
```

That's it! No fancy classes, no silly conventions. Just a convenient library for transforming files with functions.


Plugins
-------

In Lettersmith, everything is a plugin. This makes Lettersmith small, simple and easy to extend.

Lettersmith comes with a few useful plugins out of the box:

* Write [Markdown](http://daringfireball.net/projects/markdown/) with [lettersmith.markdown](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_markdown.lua)
* Use Mustache templates with [lettersmith.mustache](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_mustache.lua)
* Generate pretty permalinks with [lettersmith.permalinks](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_permalinks.lua)
* Add site metadata with [lettersmith.meta](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_meta.lua)
* Hide drafts with [lettersmith.drafts](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_drafts.lua)
* Display lists of documents with [lettersmith.collections](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_collections.lua)
* Generate automatic RSS feeds with [lettersmith.rss](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_rss.lua)

Pressed for time? The [lettersmith.blogging](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_blogging.lua) plugin bundles together Markdown, pretty permalinks, RSS feeds and more, so you can blog right out of the box.

Here's a simple blogging setup, using [Mustache](https://mustache.github.io/) templates:

```lua
local lettersmith = require("lettersmith")
local use_blogging = require("lettersmith.blogging")
local use_mustache = require("lettersmith.mustache")

local docs = lettersmith.docs("raw")

docs = use_blogging(docs)
docs = use_mustache(docs, "templates")

lettersmith.build(docs, "out")
```

Of course, this is just a start. "Plugins" are really just functions that modify a list of tables. This makes Lettersmith simple. It also means it is extremely flexible. Lettersmith can be anything you want: a website builder, a blog, a documentation generation script... If you need to transform text files, Lettersmith is an easy way to do it.


Creating new plugins
--------------------

Don't see the feature you want? No problem. "Plugins" are really just functions. Adding a feature is as easy as writing a function that changes what shows up in the document list.

For example, let's write some code to remove drafts from the list:

```lua
docs = filter(docs, function (doc)
  return not doc.draft
end)
```

Easy!

The [foldable](https://github.com/gordonbrander/lettersmith/blob/master/foldable.lua) library gives you some nice functions for working with lists of values: `map`, `filter`, `fold`, etc (you may have seen these functions before in libraries like Underscore.js).

These functions have a special sauce: they can consume nearly any value: tables, single values, nil, or _foldable functions_. What is a foldable function? The "list" that `lettersmith.docs` returns is actually a foldable function:

```lua
local docs = lettersmith.docs('raw/')
print(docs)
-- function: 0x7fc573700450
```

Why? This function is able to loop through the entire list of documents, but unlike a table, keeps only one doc in memory at a time. This allows your list of files to be infinitely large (or as large as your hard-drive can handle, anyway). In fact, Lettersmith can build _thousands_ of files in just a few _seconds_.

`map`, `filter` and cousins all consume just about any value, but return foldable functions. This means no intermediate tables are created when transforming. Efficient!

What if you want to use a `for` loop? Not to worry, `foldable.ipairs` will return a coroutine iterator you can use with traditional loops:

```lua
local foldable = require("foldable")

for i, doc in foldable.ipairs(docs) do
  print(i, doc)
end
```


What's so great about static sites?
-----------------------------------

Why use Lettersmith?

- The most important reason: it's simple.
- Blazing-fast sites on cheap hosting. Run-of-the-mill servers like Apache and nginx can serve thousands of static files per second.
- You can't hack what doesn't exist. Static sites aren't prone to being hacked, because they're entirely static... there is no program to hack.
- Your data is in plain text. No databases to worry about, no export necessary. Want to take your data elsewhere? It's all there in text files.


License
-------

The MIT License (MIT)

Copyright &copy; 2014, Gordon Brander

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
- Neither the name "Lettersmith" nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
