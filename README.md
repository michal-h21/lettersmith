Lettersmith is a simple, flexible static site generator, written in [Lua](http://lua.org).

WORK IN PROGRESS

Lettersmith is based on a simple idea: load files as tables. So this:

`example.md`:

```markdown
---
title: Example title
---
An example post
```

...Becomes this:

```lua
{
  relative_filepath = 'example.md',
  contents = 'An example post',
  title = "Example title"
}
```

You can add metadata to the table using a [YAML](yaml.org) headmatter block at the top of the file. Any properties you put there will show up on the object. If you don't want metadata, you can skip the headmatter block completely.

`lettersmith.docs` takes a filepath and returns a list of tables:

```lua
{
  relative_filepath = 'foo/x.md',
  contents = '...',
},
{
  relative_filepath = 'bar/y.md',
  contents = '...',
},
...
```

That's it! No fancy classes, no silly conventions, no magic. Just a convenient library for processing files with functions.

Creating a site is simple. Just create a new lua file. Call it anything you like.

```lua
local lettersmith = require("lettersmith")
local use_markdown = require("lettersmith-markdown")
local filter = require("colist").filter

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

* Render markdown posts with `lettersmith-markdown`
* Add site metadata to posts with `lettersmith-meta`
* Mustache templates with `lettersmith-mustache`
* Hide draft posts with `lettersmith-drafts`

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

Just like a table, you can use `for` to loop over items inside. However, unlike a table, only one doc exists in memory at a time. This lets us load in massive numbers of files without a problem. The library `colist` gives you standard `map`, `filter`, `reduce` functions that will also return generators.

Fancy generators not your thing? Just use `colist.collect` to load all docs into a standard Lua table:

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


Status
------

Core @todo

* Package as Luarock
* Windows hasn't been tested. Should be an easy fix. LFS supports Win, but we might need to do some filepath conversion.
  - Will also need to deal with opening files in "text mode" vs binary.
* (Maybe) alternative site config approach based on Lua tables or YAML
* Someday: embed into Mac app for drag/drop site generation
* <strike>Need to fix writing to nested directories</strike> @done
* <strike>Clean previous build dir before writing new one </strike> @done

Themes @todo

* Default theme that can be used by calling a single function
* Twitter Bootstrap theme

Plugins @todo

* `lettersmith-permalinks` for clean urls. `about.html` -> `about/index.html`.
* `lettersmith-thumbnails` for generating multiple image sizes. Someting like `use_thumbnails(docs, { { w: 200, h: 200, crop: true } })`.
  * lua-gd https://ittner.github.io/lua-gd/
  * http://lua-users.org/wiki/GdThumbnail
  * Lua imagemagick bindings https://github.com/leafo/magick
  * lua-thumbnailer https://github.com/mah0x211/lua-thumbnailer 
* `lettersmith-query` to easily generate lists of docs, filtered and sorted.
* `lettersmith-pagninate` for creating lists of pages of queried files and linking prev/next files. This could actually be lumped in with `lettersmith-query`.
* `lettersmith-watch` watch files for modification and re-build.
* `lettersmith-local` local server that watches files using `lettersmith-watch` and serves up the results.
* `lettersmith-excerpt` create from first sentence or title.
* `lettersmith-hash` calc hash of file contents http://keplerproject.org/md5/
* `lettersmith-date` calc nice dates from date field or file changed date. Maybe this should be part of core?
  * http://stackoverflow.com/questions/23486318
  * http://lua-users.org/wiki/DateAndTime
  * http://lua-users.org/wiki/DateFormattingFunctions
  * https://rocks.moonscript.org/modules/tieske/date
* `lettersmith-tags` tagging via headmatter
* `lettersmith-hashtags` tagging via `#hashtags`
* `lettersmith-haml` https://github.com/norman/lua-haml
* `lettersmith-sass`
  * https://github.com/sass/libsass
  * https://github.com/craigbarnes/lua-sass


License
-------

The MIT License (MIT)

Copyright &copy; 2014, Gordon Brander

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
