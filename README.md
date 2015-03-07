Lettersmith
===========

Lettersmith is a simple, flexible, fast  _static site generator_. It's written in [Lua](http://lua.org).

Lettersmith's goals are:

- Simple
- Flexible: everything is a plugin.
- Fast: build thousands of pages in seconds or less.
- Embeddable: we're going to put this thing in an Mac app so normal people can use it.

Lettersmith is open-source and a work-in-progress. [You can help](https://github.com/gordonbrander/lettersmith/issues).


What does it do?
----------------

Lettersmith is based on a simple idea: load files as Lua tables. So this:

`2015-03-01-example.md`:

```markdown
---
title: Trying out Lettersmith
---
Let's add some content to this file.
```

...Becomes this:

```lua
{
  relative_filepath = "2015-03-01-example.md",
  title = "Trying out Lettersmith",
  contents = "Let's add some content to this file.",
  date = "2015-03-01"
}
```

- The file contents will end up in the `contents` field.
- You can add an optional [YAML](yaml.org) headmatter block to files. Any YAML properties you put in the block will show up on the table!
- Date will be inferred from file name, but you can provide your own by adding a `date` field to the headmatter.

The function `lettersmith.paths(directory)` returns a table of file paths in that `directory`, sorted by file name. You can then transform those paths using plugins.

The most basic plugin is `lettersmith.docs(paths_table)`. It takes a Lettersmith
paths table and returns an iterator of tables.

```lua
local paths = lettersmith.paths("raw")
local docs = lettersmith.docs(paths)

for doc in docs do
  print(doc)
end

--[[
{
  relative_filepath = "foo/x.md",
  contents = "...",
  date = "2014-10-17"
}
...
]]--
```


Creating a site
---------------

Creating a site is simple. Just create a new lua file. Call it anything you like.

```lua
local lettersmith = require("lettersmith")
local render_markdown = require("lettersmith.markdown")

-- Get paths from "raw" folder
local paths = lettersmith.paths("raw")

-- Render markdown
local docs = lettersmith.docs(paths)
docs = render_markdown(docs)

-- Build files, writing them to "www" folder
lettersmith.build("www", docs)
```

That's it! No fancy classes or complex conventions. Just a convenient library for transforming files with functions.

What if you want to combine a series of plugins? No problem. Lettersmith plugins are composable:

```lua
-- ...
local comp = require("lettersmith.transducers").comp

local blog_post = comp(
  render_permalinks ":yyyy/:mm/:slug",
  use_meta { site_title = "..." },
  render_markdown,
  lettersmith.docs
)

local blog_single = comp(
  render_mustache "templates/blog_single.html",
  blog_post
)

local blog_archive = comp(
  render_mustache "templates/blog_archive.html",
  paging "page/:n/index.html",
  blog_post
)

build("www", blog_single(paths), blog_archive(paths))
```


Plugins
-------

In Lettersmith, everything is a plugin. This makes Lettersmith small, simple and easy to extend.

Lettersmith comes with a few useful plugins out of the box:

* Write [Markdown](http://daringfireball.net/projects/markdown/) with [lettersmith.markdown](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_markdown.lua)
* Use Mustache templates with [lettersmith.mustache](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_mustache.lua)
* Generate pretty permalinks with [lettersmith.permalinks](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_permalinks.lua)
* Add site metadata with [lettersmith.meta](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_meta.lua)
* Hide drafts with [lettersmith.drafts](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_drafts.lua)
* Generate automatic RSS feeds with [lettersmith.rss](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_rss.lua)

<!--
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
-->

Of course, this is just a start. "Plugins" are really just functions that modify a list of tables. This makes Lettersmith simple. It also means it is extremely flexible. Lettersmith can be anything you want: a website builder, a blog, a documentation generation script... If you need to transform text files, Lettersmith is an easy way to do it.


Creating new plugins
--------------------

Don't see the feature you want? No problem. Creating a plugin is easy! "Plugins" are really just functions that return an iterator function.

For example, let's write a plugin to remove drafts:

```lua
local function remove_drafts(iter)
  return coroutine.wrap(function()
    for doc in iter do
      if not doc.draft then
        coroutine.yield(doc)
      end
    end
  end)
end
```

We typically use Lua `coroutines` to create iterators because they're lazy, allowing us to build 1000s of files without consuming too much memory at once.

Lettersmith provides some handy tools for transforming iterators: `lettersmith.transducers` and `lettersmith.lazy`. Let's use these to rewrite the drafts plugin:

```lua
local filter = require("lettersmith.transducers").filter
local transformer = require("lettersmith.lazy").transformer

local remove_drafts = transformer(filter(function (docs)
  return not doc.draft
end))
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
