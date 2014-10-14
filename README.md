Lettersmith is a minimal static site generator.

WORK IN PROGRESS

Design approach
---------------

No fancy classes, no silly conventions, no magic. Just a convenient library for processing files with functions.

Will eventually look something like this:

```lua
local lettersmith = require('lettersmith')

local docs = lettersmith.docs('raw')

docs = parse_markdown(docs)

-- Create custom "plugin" to remove drafts. It's just a function!
docs = filter(docs, function (doc)
  return not doc.draft
end)

-- Build files
lettersmith.build("out", docs)
```

`lettersmith.docs` takes a filepath and returns a list of tables that look like this:

    {
      relative_filepath = 'foo/x.md',
      contents = '...',
    }

That's it!


Plugins
-------

Extending Lettersmith with new functionality is easy. There are no fancy plugin conventions to learn, just modify the documents list!

Lettersmith comes with a few useful plugins out of the box:

* Render markdown posts with `lettersmith-markdown`
* Add site metadata to posts with `lettersmith-meta`
* Mustache templates with `lettersmith-mustache`
* Hide draft posts with `lettersmith-drafts`

Of course, this are just a start. If you see something missing, adding it is as easy as adding a function.


Misc thoughts
-------------

I don't mind this:

    local docs = lettersmith.docs('raw')
    docs = markdown(docs)
    docs = mustache(docs, 'templates')

But I know some people prefer method chaining or composition. If plugins consumed and returned only `docs`, and all other methods were curried:

    local docs = pipe(lettersmith.docs('raw'), site_meta, markdown, mustache)

Not bad. It's terse, but there is a loss of obviousness. Maybe the better approach is simply to build a DSL or use YAML config (if you want it).

    {
        markdown = {},
        meta = { site_title: 'My website' }
        mustache = { 'templates' }
    }

---

Entire themes could be built as single functions. You could wrap markdown, mustache and a bunch of template and CSS files into a package, then import it.


License
-------

The MIT License (MIT)

Copyright &copy; 2014, Gordon Brander

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
