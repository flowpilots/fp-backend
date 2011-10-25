http = require("http")
fs = require("fs")
coffee = require("coffee-script")
uglify = require("uglify-js")
findit = require("findit")

compiler = (name, basepath, path, pack, cb) ->
    # Adapted from jade's compile script.
    files = {}

    stripPrefix = new RegExp("^#{basepath}\/#{path}/")
    output = basepath + "/public/js/#{name}.js"
    min_output = basepath + "/public/js/#{name}.min.js"
    pack = pack.slice()
    pack.push "#{name}.js"

    walk = (dir, done) ->
        results = []
        finder = findit.find(dir)
        finder.on 'file', (file) ->
            results.push file
        finder.on 'end', () ->
            done null, results

    # Parse the given 'js'.
    parse = (js) ->
        parseInheritance parseConditionals(js)

    # Parse __proto__.
    parseInheritance = (js) ->
        js.replace /^ *(\w+)\.prototype\.__proto__ * = *(\w+)\.prototype *;?/g, (_, child, parent) ->
            child + ".prototype = new " + parent + ";\n" + child + ".prototype.constructor = " + child + ";\n"

    # Parse the given `js`, currently supporting:
    # 
    #    'if' ['node' | 'browser']
    #    'end'
    parseConditionals = (js) ->
        lines = js.split("\n")
        len = lines.length
        buffer = true
        browser = false
        buf = []
        i = 0
        
        while i < len
            line = lines[i]
            if /^ *\/\/ *if *(node|browser)/g.exec(line)
                cond = RegExp.$1
                buffer = browser = "browser" == cond
            else if /^ *\/\/ *end/.test(line)
                buffer = true
                browser = false
            else if browser
                buf.push line.replace(/^( *)\/\//, "$1")
            else buf.push line if buffer
            ++i
        buf.join "\n"

    # Compile the files
    compile = (args) ->
        buf = ""
        buf += "\n// CommonJS require()\n\n"
        buf += "require = " + browser.require + ";\n\n"
        buf += "require.modules = {};\n\n"
        buf += "require.resolve = " + browser.resolve + ";\n\n"
        buf += "require.register = " + browser.register + ";\n\n"
        buf += "require.relative = " + browser.relative + ";\n\n"
        args.forEach (file) ->
            return if /.swp$/.test(file)
            file = file.replace(/coffee$/, "js") if /.coffee$/.test(file)
            js = files[file]
            file = file.replace(stripPrefix, "")
            buf += "\nrequire.register(\"" + file + "\", function(module, exports, require){\n"
            buf += js
            buf += "\n}); // module: " + file + "\n"
        
        fs.writeFile output, buf, (err) ->
            throw err if err
            console.log "    \u001b[90m create : \u001b[0m\u001b[36m%s\u001b[0m", "public/js/#{name}.js"
            console.log ""
            cb() if cb

            # Wait 5 seconds before minify, to make the app start first.
            setTimeout minify, 5000

    # Run the compilation loop
    main = (err, args) ->
        throw err if err
        args.sort()
        pending = args.length
        console.log ""
        compiled = []
        args.forEach (file) ->
            if not /.(coffee|js)$/.test(file)
                --pending
                return
            compiled.push file
            mod = file.replace(stripPrefix, "")
            fs.readFile file, "utf8", (err, js) ->
                throw err if err
                console.log "    \u001b[90mcompile : \u001b[0m\u001b[36m%s\u001b[0m", mod
                if /.coffee$/.test(file)
                    js = coffee.compile(js, filename: file)
                    file = file.replace(/coffee$/, "js")
                files[file] = parse(js)
                --pending or compile compiled

    # Minify loop, happens after the callback
    minify = () ->
        console.log()
        pending = pack.length

        srcbuf = {}

        write_out = () ->
            buf = ""
            pack.forEach (file) ->
                buf += srcbuf[file]
            jsp = uglify.parser
            pro = uglify.uglify
            ast = jsp.parse(buf)
            ast = pro.ast_mangle(ast)
            ast = pro.ast_squeeze(ast)
            out = pro.gen_code(ast)
            fs.writeFile min_output, out, (err) ->
                throw err  if err
                console.log "  \u001b[90m create : \u001b[0m\u001b[36m%s\u001b[0m", "public/js/#{name}.min.js"
                console.log()

        pack.forEach (file) ->
            console.log "  \u001b[90m   read : \u001b[0m\u001b[36m%s\u001b[0m", file
            fs.readFile basepath + '/public/js/' + file, "utf8", (err, out) ->
                throw err if err
                srcbuf[file] = out
                --pending or write_out()

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

    # Compile all files
    walk basepath + '/' + path, main

module.exports = (basepath, options) ->
        (req, res, next) ->
            if req.app.settings.env != 'development'
                return next()

            found = false
            for name, opts of options
                if req.url == "/js/#{name}.js"
                    found = true
                    compiler name, basepath, opts.path, opts.pack, () ->
                        next()

            return next() if !found
