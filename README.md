Lettersmith is a minimal static site generator.

WORK IN PROGRESS

Lettersmith is based on a simple idea: load files as a list of tables.

`lettersmith.docs` takes a filepath and returns a list of tables that look like this:

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

Of course, this are just a start. If you see something missing, adding it is as easy as adding a function.


Manipulating your files
-----------------------

Don't see the plugin you want? Writing one yourself is a cinch.

The list that `lettersmith.docs` returns is a Lua generator function. That means your list of files can be infinite (or as large as your hard-drive can handle, anyway).

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

for doc in docs do print(doc.contents) end
-- "..."
-- "..."
-- "..."
```


Status
------

* @TODO need to fix writing to nested directories
* Windows hasn't been tested. Should be an easy fix. I think LFS supports Win, but we might need to do some filepath conversion.


License
-------

The MIT License (MIT)

Copyright &copy; 2014, Gordon Brander

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
