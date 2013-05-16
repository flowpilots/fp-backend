v0.8.0 (16/05/2013)
===================

Massive version bump for Mongoose, fixes Node 0.10 problems.

v0.7.6 (06/05/2013)
===================

Compile rather than bundle CoffeeScript.

v0.7.5 (06/05/2013)
===================

Make engines less strict.

v0.7.4 (06/05/2013)
===================

Upgrade Express for Node 0.10 compat.

v0.7.3 (24/04/2013)
===================

Don't run autoquit in development mode.

v0.7.2 (09/04/2013)
===================

Fix versioning.

v0.7.1 (09/04/2013)
===================

Fix autoquit issue.

v0.7.0 (09/04/2013)
===================

Upgrade to Express 3.

v0.6.1 (26/03/2013)
===================

Periodically remove sessions.

v0.6.0 (20/03/2013)
===================

Branch off for 0.6: exclude client-compiler.

Remove stylus support.

v0.5.9 (04/01/2013)
===================

Windows support for client-compile.

v0.5.8 (03/09/2012)
===================

Fix silly mistake, that's what you get from not testing.

v0.5.7 (03/09/2012)
===================

Make the session cookie name app-specific.

v0.5.6 (01/08/2012)
===================

Limit the number of minifiers to two.

v0.5.5 (01/08/2012)
===================

New asset compiler

v0.5.4 (31/07/2012)
===================

Switch to a non-broken version of the closure compiler.

v0.5.3 (30/07/2012)
===================

Remove broken gzip module.

v0.5.2 (27/07/2012)
===================

Pass the express context to configure.

v0.5.1 (27/07/2012)
===================

Merge changes, last one was a botched release.

v0.5.0 (27/07/2012)
===================

Start on a 0.5.x branch for Node 0.8.

v0.4.7 (20/07/2012)
===================

CSS Sprite support.

v0.4.6 (19/07/2012)
===================

Jade templates for the client, precompiled.

v0.4.5 (18/07/2012)
===================

Two small JS pack improvements: file name prefixing and initialization code.

v0.4.4 (18/07/2012)
===================

Allow skipping headers on JS packing.

v0.4.3 (04/07/2012)
===================

Fix version clash with superagent.

v0.4.2 (04/07/2012)
===================

Attempt to unbreak Jade.

v0.4.1 (25/05/2012)
===================

Add crash reporter, no changes needed.

v0.4.0 (17/05/2012)
===================

Switch to node 0.6.18.

v0.3.9 (01/04/2012)
===================

Upgrade autoquit to 0.1.2. No project changes needed.

v0.3.8 (01/04/2012)
===================

Upgrade autoquit to 0.1.1. No project changes needed.

v0.3.7 (01/04/2012)
===================

Hook in autoquit. This will shut down daemons in production after a certain
amount of time. This is on by default so disable it in your project if this is
not intended behavior.

v0.3.6 (25/01/2012)
===================

Don't add semi-colons to min.js, that's safe already.

v0.3.5 (25/01/2012)
===================

Safely concatenate files by adding semicolons.

v0.3.4 (05/01/2012)
===================

Full immediate logging.

Change >= to ~ in dependency specs.

v0.3.3 (29/12/2011)
===================

Warn when coffeescript compilation fails.

v0.3.2 (27/12/2011)
===================

Allow overriding the Mongo database using a MONGO_DB environment variable.

v0.3.1 (19/12/2011)
===================

Output a message when bundles have been written.

v0.3.0 (16/12/2011)
===================

Switch to the Google Closure Compiler for JS-minification as uglify-js breaks
things. Doing a major version bump because this may in turn break things even
though I highly doubt it.

v0.2.2 (01/04/2012)
===================

Hook in autoquit. This will shut down daemons in production after a certain
amount of time. This is on by default so disable it in your project if this is
not intended behavior.

v0.2.1 (23/11/2011)
===================

Renamed Session to ActiveSession to avoid clashes with user-space code in the
mongo database.

v0.2.0 (21/11/2011)
===================

Changes to the client-compiler, which now requires you to include
'name.bundle.js' in development and 'name.bundle.min.js' in production.

Project changes required:
* Load the .bundle.js. Put this in your view:
  script(src='/js/app.bundle.' + (process.env.NODE_ENV == 'production' ? 'min.js' : 'js'))
