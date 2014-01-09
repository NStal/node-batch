require "coffee-script"
fs = require "fs"
path = require "path"
async = require "async"
exports.batchSolve = (handler,listpath,option={})->
    file = fs.readFileSync(listpath,"utf8")
    lines = file.split("\n").map (item)->
        item = item.trim()
        if option.retry and item.indexOf("#fail") is 0
            return item.replace("#fail","")
        return item
        
    lines = lines.filter (item)->
        item and item[0] isnt "#"
    results = []
    success = 0
    fail = 0
    async.eachLimit lines,1,((line,done)->
        handler line,(err)->
            if err
                console.log("fail #{line}")
                results.push("#fail::#{line}")
                fail++
            else
                console.log("success #{line}")
                results.push("#success::#{line}")
                success++
            done()
        ),(err)->
            console.log("end...")
            fs.writeFileSync(listpath,new Buffer(results.join("\n\r")))
            if option.callback
                option.callback null,{success:success,fail:fail}


if not module.parent
    usageError = ()->
        console.log "usage #{process.argv[0]} #{process.argv[1]} <script path> <list path>"
        process.exit(0)
    panic = ()->
        console.log.apply(console,arguments)
        process.exit(1)
    scriptPath = process.argv[2];
    listPath = process.argv[3];
    if not scriptPath or not listPath
        usageError()
    scriptPath = path.join(path.resolve("./"),scriptPath)
    if not fs.existsSync(scriptPath)
        panic("script #{scriptPath} not exists")
    if not fs.existsSync(listPath)
        panic("list #{listPath} not exists")
    try
        handlerScript = require(scriptPath)
    catch e
        panic("invalid script #{e.toString()}")
    if typeof handlerScript.handle isnt "function"
        panic("script's #{scriptPath} handle method is not a function")
    exports.batchSolve handlerScript.handle,listPath,{
        callback:(err,result)->
            console.log "success:",result
            console.log "fail:",fail
        }
    