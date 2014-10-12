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