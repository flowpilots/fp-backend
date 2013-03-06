_ = require 'underscore'
async = require 'async'
closure = require 'closure-compiler'
coffee = require 'coffee-script'
walkdir = require 'walkdir'
fs = require 'fs'
jade = require 'jade'
jadevu = require 'jadevu'
mkdirp = require 'mkdirp'
path = require 'path'

Require =
    create: (path = '.') ->
        fn = (module) ->
            Require.load(module, path)

        # Utility shortcut.
        fn.new = (file, a, b) ->
            type = fn(file)
            return new type(a, b)

        return fn

    # Register a module
    register: (path, fn) ->
        Require.modules[path] = fn

    load: (module, path = '.') ->
        location = module
        if module[0] == '.'
            location = path + '/../' + module
        pieces = []
        for piece in location.split('/')
            if piece == '.' || piece == ''
                continue
            else if piece == '..'
                pieces.pop()
            else
                pieces.push piece
        p = pieces.join('/')

        return a if a = Require.exports[p]

        fn = Require.modules[p]
        throw new Error("failed to require \"#{p}\" from \"#{path}\"") unless fn

        mod = {
            name: p
            exports: {}
        }
        fn.call mod.exports, mod, mod.exports, Require.create(p)
        Require.exports[p] = mod.exports
        return mod.exports
    

runTask = (task, cb) -> task.exec cb
minifier = async.queue runTask, 2

class SourceFile
    constructor: (@compileUnit, @fileName) ->
        @output = ''

        prefix = @compileUnit.compiler.options.requirePrefix || ""
        strip = @compileUnit.compiler.stripPrefix

        @name = prefix + @fileName.substring(strip.length).replace(/(\.(coffee|js))$/, "")

    prepare: (cb) ->
        async.series [
            (cb) => fs.readFile @fileName, "utf8", (err, @output) => cb(err)
            (cb) => @process(cb)
            (cb) => @wrap(cb)
        ], cb

    process: (cb) -> cb(null)

    wrap: (cb) -> cb(null)

class JavaScriptSourceFile extends SourceFile
    wrap: (cb) ->
        @output = "Require.register(\"#{@name}\", function (module, exports, require) {\n#{@output}\n});\n// Module: #{@name}\n"
        cb(null)

class CoffeeScriptSourceFile extends JavaScriptSourceFile
    process: (cb) ->
        @output = coffee.compile(@output, filename: @fileName)
        cb(null)

class JadeSourceFile extends SourceFile
    process: (cb) ->
        fn = jade.compile(@output, filename: @fileName)
        template = fn()
        start = "<script>".length
        start = template.indexOf("window.template._[") if @compileUnit.haveJade
        @compileUnit.haveJade = true
        @output = template.substring(start, template.length - "</script>".length)
        cb(null)

    wrap: (cb) ->
        @output = "// Jade: #{@name}\n#{@output}\n// End Jade: #{@name}\n"
        cb(null)

class CompileUnit
    process: (cb) -> cb(null)

    minify: (cb) ->
        statReply = (cb) ->
            (err, stats) ->
                err = null if err and err.code = 'ENOENT'
                cb(err, stats)

        async.parallel
            min: (cb) => fs.stat @minFile, statReply(cb)
            max: (cb) => fs.stat @maxFile, statReply(cb)
        , (err, data) =>
            return cb(err) if err
            return cb() if data.min && data.min.mtime >= data.max.mtime

            fs.readFile @maxFile, 'utf8', (err, src) =>
                return cb(err) if err

                task =
                    exec: (cb) =>
                        @doMinify(src, cb)


                minifier.push task, cb

    doMinify: (src, cb) ->
        closure.compile src, (err, out) =>
            return cb(err) if err
            console.log "  \u001b[90m   create : \u001b[0m\u001b[36m%s\u001b[0m", @minFile.replace(@compiler.tmpPath, "tmp/js")
            fs.writeFile @minFile, out, cb

class LibraryCompileUnit extends CompileUnit
    constructor: (@compiler, @name) ->
        @maxFile = path.join @compiler.libPath, "#{@name}.js"
        @minFile = path.join @compiler.tmpPath, "#{@name}.min.js"

    doMinify: (src, cb) ->
        bundledPath = @maxFile.replace(/\.js$/, ".min.js")
        fs.exists bundledPath, (exists) =>
            if exists
                # Reuse bundled minified file.
                console.log "  \u001b[90m   copy   : \u001b[0m\u001b[36m%s\u001b[0m", bundledPath.replace(@compiler.libPath, "lib/js")
                out = fs.createWriteStream(@minFile)
                out.on 'close', cb
                fs.createReadStream(bundledPath).pipe(out)
                return

            # Minify it ourselves.
            super(src, cb)

class SourceDirCompileUnit extends CompileUnit
    constructor: (@compiler) ->
        @srcPath = path.join @compiler.basePath, @compiler.options.path
        @maxFile = path.join @compiler.tmpPath, "#{@compiler.name}.js"
        @minFile = path.join @compiler.tmpPath, "#{@compiler.name}.min.js"

        @inputs = []
        @haveJade = false

    prepare: (cb) ->
        finder = walkdir(@srcPath)
        finder.on 'file', (file) => @queueSourceFile file
        finder.on 'end', (err) =>
            return cb(err) if err
            @inputs = _.sortBy @inputs, (input) -> input.fileName
            cb(null)

    queueSourceFile: (file) ->
        @inputs.push new CoffeeScriptSourceFile(@, file) if /\.coffee$/.test(file)
        @inputs.push new JavaScriptSourceFile(@, file) if /\.js$/.test(file)
        @inputs.push new JadeSourceFile(@, file) if /\.jade$/.test(file)

    makeHeader: () ->
        buf = ""
        buf += "if (typeof(require) == 'undefined') {"
        buf += "    Require = {\n"
        buf += "        create: " + Require.create + ",\n"
        buf += "        register: " + Require.register + ",\n"
        buf += "        load: " + Require.load + ",\n"
        buf += "        modules: {},\n"
        buf += "        exports: {}\n"
        buf += "    };"
        buf += "    require = Require.create();\n"
        buf += "}"
        return buf

    process: (cb) ->
        prepareSource = (file, cb) -> file.prepare(cb)
        async.forEachSeries @inputs, prepareSource, (err) =>
            return cb(err) if err
            
            buf = ""
            if !@compiler.options.skipHeader
                buf += @makeHeader()

            for item in @inputs
                buf += item.output

            if @compiler.options.initWith
                buf += "require(\"#{@compiler.options.initWith}\");\n"

            console.log "  \u001b[90m   create : \u001b[0m\u001b[36m%s\u001b[0m", @maxFile.replace(@compiler.tmpPath, "tmp/js")
            fs.writeFile @maxFile, buf, cb

class Compiler
    constructor: (basePath, @name, @options = {}) ->
        @basePath = path.normalize basePath
        @tmpPath = path.normalize @basePath + "/tmp/js"
        @outPath = path.normalize @basePath + "/public/js"
        @libPath = path.normalize @basePath + "/lib/js"

        @stripPrefix = path.join(@basePath, @options.path) + '/'
        @buildQueue = []

    prepareOutput: (cb) ->
        async.parallel [
            (cb) => mkdirp @tmpPath, cb
            (cb) => mkdirp @outPath, cb
        ], cb

    queueLibraries: (cb) ->
        for lib in @options.pack
            @buildQueue.push new LibraryCompileUnit(@, lib)
        cb()

    queueSource: (cb) ->
        unit = new SourceDirCompileUnit(@)
        @buildQueue.push unit
        unit.prepare(cb)

    processQueue: (cb) ->
        buildItem = (item, cb) -> item.process(cb)
        async.forEach @buildQueue, buildItem, cb

    bundle: (file, out, separator, cb) ->
        sources = []

        bundleItem = (item, cb) ->
            fs.readFile item[file], 'utf8', (err, src) ->
                return cb(err) if err
                sources.push src
                cb()

        async.forEachSeries @buildQueue, bundleItem, (err) =>
            return cb(err) if err
            console.log "  \u001b[90m   bundle : \u001b[0m\u001b[36m%s\u001b[0m", out.replace(@outPath, "public/js")
            fs.writeFile out, sources.join(separator), cb

    bundleMax: (cb) -> @bundle('maxFile', @outPath + "/#{@name}.bundle.js", ";\n", cb)
    bundleMin: (cb) -> @bundle('minFile', @outPath + "/#{@name}.bundle.min.js", "\n", cb)

    minifyQueue: (cb) ->
        minify = (item, cb) -> item.minify(cb)
        async.forEach @buildQueue, minify, cb

    compile: (cb) ->
        async.series [
            (cb) => @prepareOutput(cb)
            (cb) => @queueLibraries(cb)
            (cb) => @queueSource(cb)
            (cb) => @processQueue(cb)
            (cb) => @bundleMax(cb)
        ], (err) =>
            return cb(err) if err
            cb(null) if !@options.wait

            async.series [
                (cb) => @minifyQueue(cb)
                (cb) => @bundleMin(cb)
            ], (err) =>
                cb(err) if @options.wait

module.exports = (basepath, options) ->
        (req, res, next) ->
            return next() if req.app.settings.env != 'development'

            found = false
            for name, opts of options
                if req.url == "/js/#{name}.bundle.js"
                    found = true
                    #compiler name, basepath, opts, (err) ->
                    #    return next(err) if err

                    c = new Compiler(basepath, name, opts)
                    c.compile(next)

            return next() if !found
