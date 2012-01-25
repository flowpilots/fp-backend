async = require("async")
http = require("http")
fs = require("fs")
coffee = require("coffee-script")
closure = require("closure-compiler")
findit = require("findit")

compiler = (name, basepath, path, pack, cb) ->
    stripPrefix = new RegExp("^#{basepath}\/#{path}/")
    pack = pack.slice()
    pack.push name

    statReply = (cb) ->
        (err, stats) ->
            err = null if err and err.code = 'ENOENT'
            cb(err, stats)

    minify = (item, cb) ->
        console.log "  \u001b[90m   create : \u001b[0m\u001b[36m%s\u001b[0m", "public/js/#{item}.min.js"
        file = basepath + "/public/js/#{item}.js"
        min_file = basepath + "/public/js/#{item}.min.js"
        fs.readFile file, "utf8", (err, js) ->
            cb(err) if err
            closure.compile js, (err, out) ->
                return cb(err) if err
                fs.writeFile min_file, out, (err) ->
                    cb(err)

    prepareMinified = (item, minCb) ->
        async.parallel
            devel: (cb) -> fs.stat basepath + "/public/js/#{item}.js", statReply(cb)
            min: (cb) -> fs.stat basepath + "/public/js/#{item}.min.js", statReply(cb)
        , (err, data) ->
            minCb(err) if err

            if !data.min || data.min.mtime < data.devel.mtime
                minify(item, minCb)
            else
                minCb()

    walk = (dir, done) ->
        results = []
        finder = findit.find(dir)
        finder.on 'file', (file) ->
            results.push file
        finder.on 'end', () ->
            done null, results

    prepareFile = (compiled) ->
        (file, cb) ->
            return cb() if not /.(coffee|js)$/.test(file)
            fs.readFile file, "utf8", (err, js) ->
                return cb(err) if err
                mod = file.replace(stripPrefix, "")
                console.log "    \u001b[90mcompile : \u001b[0m\u001b[36m%s\u001b[0m", mod
                try
                    if /.coffee$/.test(file)
                        js = coffee.compile(js, filename: file)
                        throw new Error("CoffeeScript compile failed for #{file}") if !js
                        file = file.replace(/coffee$/, "js")
                    compiled[file] = js
                    cb()
                catch e
                    cb(e)

    prepareSource = (cb) ->
        walk basepath + '/' + path, (err, args) ->
            cb(err) if err
            args.sort()

            compiled = {}
            async.forEachSeries args, prepareFile(compiled), (err) ->
                cb(err) if err

                buf = ""
                buf += "\n// CommonJS require()\n\n"
                buf += "require = " + browser.require + ";\n\n"
                buf += "require.modules = {};\n\n"
                buf += "require.resolve = " + browser.resolve + ";\n\n"
                buf += "require.register = " + browser.register + ";\n\n"
                buf += "require.relative = " + browser.relative + ";\n\n"

                args.forEach (file) ->
                    return if not /.(coffee|js)$/.test(file)
                    file = file.replace(/coffee$/, "js") if /.coffee$/.test(file)
                    js = compiled[file]
                    file = file.replace(stripPrefix, "")
                    buf += "\nrequire.register(\"" + file + "\", function(module, exports, require){\n"
                    buf += js
                    buf += "\n}); // module: " + file + "\n"

                console.log "    \u001b[90m create : \u001b[0m\u001b[36m%s\u001b[0m", "public/js/#{name}.js"
                fs.writeFile basepath + "/public/js/#{name}.js", buf, (err) ->
                    cb(err)

    # refactored version of weepy's
    # https://github.com/weepy/brequire/blob/master/browser/brequire.js
    browser =
        # Require a module.
        require: (p) ->
            path = require.resolve(p)
            mod = require.modules[path]
            throw new Error("failed to require \"" + p + "\"") unless mod
            unless mod.exports
                mod.exports = {}
                mod.call mod.exports, mod, mod.exports, require.relative(path)
            mod.exports
        
        # Resolve module path.
        resolve: (path) ->
            orig = path
            reg = path + ".js"
            index = path + "/index.js"
            require.modules[reg] and reg or require.modules[index] and index or orig
        
        # Return relative require().
        relative: (parent) ->
            (p) ->
                return require(p) unless "." == p[0]
                path = parent.split("/")
                segs = p.split("/")
                path.pop()
                i = 0
                
                while i < segs.length
                    seg = segs[i]
                    if ".." == seg
                        path.pop()
                    else path.push seg unless "." == seg
                    i++
                require path.join("/")
        
        # Register a module
        register: (path, fn) ->
            require.modules[path] = fn

    mergeTo = (ext, list) ->
        (item, cb) ->
            file = basepath + "/public/js/#{item}.#{ext}"
            fs.readFile file, "utf8", (err, js) ->
                cb(err) if err
                list.push js
                cb()

    mergeMinifiedBundle = (cb) ->
        cb(null) # Invoking CB immediately, the rest can happen in the background

        async.forEach pack, prepareMinified, (err) ->
            throw err if err

            minSrc = []
            async.forEachSeries pack, mergeTo('min.js', minSrc), (err) ->
                throw err if err
                fs.writeFile basepath + "/public/js/#{name}.bundle.min.js", minSrc.join(';\n'), (err) ->
                    console.log "  \u001b[90m    write : \u001b[0m\u001b[36m%s\u001b[0m", "public/js/#{name}.bundle.min.js"
                    throw err if err

    mergeBundle = (cb) ->
        develSrc = []
        async.forEachSeries pack, mergeTo('js', develSrc), (err) ->
            return cb(err) if err
            fs.writeFile basepath + "/public/js/#{name}.bundle.js", develSrc.join(';\n'), (err) ->
                console.log "  \u001b[90m    write : \u001b[0m\u001b[36m%s\u001b[0m", "public/js/#{name}.bundle.js"
                cb(err)

    async.series [
        prepareSource
        mergeBundle
        mergeMinifiedBundle
    ], cb

module.exports = (basepath, options) ->
        (req, res, next) ->
            return next() if req.app.settings.env != 'development'

            found = false
            for name, opts of options
                if req.url == "/js/#{name}.bundle.js"
                    found = true
                    compiler name, basepath, opts.path, opts.pack, () ->
                        next()

            return next() if !found
