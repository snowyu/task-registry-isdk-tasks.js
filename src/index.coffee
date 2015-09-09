setPrototypeOf = require 'inherits-ex/lib/setPrototypeOf'
isObject    = require 'util-ex/lib/is/type/object'
isString    = require 'util-ex/lib/is/type/string'
isArray     = require 'util-ex/lib/is/type/array'
extend      = require 'util-ex/lib/_extend'
SeriesTask  = require 'task-registry-series'
register    = SeriesTask.register
aliases     = SeriesTask.aliases
getKeys     = Object.keys

# pipeline: execute tasks with aOptions if the first task has no arguments.
# non-pipeline: execute tasks with aOptions if the task has no arguments.
module.exports = class IsdkTasks
  register IsdkTasks
  aliases IsdkTasks, 'Tasks', 'tasks'

  constructor: -> return super

  #process a task.
  _initTask: (task, aOptions)->
    assignOptsToTask = (aName)->
      if task[aName]?
        if task[aName].hasOwnProperty '<'
          vOpts = task[aName]['<'] # task's inherited options
          vOpts = extend {}, vOpts
          setPrototypeOf vOpts, aOptions
          task[aName] = vOpts
      else
        task[aName] = aOptions
      return

    if isObject task
      task = extend {}, task
      vNames = getKeys task # get the task names. 'task': options
      if vNames.length
        if aOptions.pipeline
          assignOptsToTask vNames[0]
        else for name in vNames
          assignOptsToTask name
    else if isString task
      vTask = {}
      vTask[task] = aOptions
      task = vTask
    task

  # pipeline: pass the aOptions to the first task if the first has no arguments.
  # non-pipeline: pass the aOptions to the task if the task has no arguments.
  _initTasks: (aOptions)->
    if isString aOptions
      vTasks = [aOptions]
      result = tasks: vTasks
      aOptions = null
    else if isArray aOptions
      vTasks = aOptions.slice()
      result = tasks: vTasks
      aOptions = null
    else if isObject aOptions
      vTasks = aOptions.tasks
      vPipeline = aOptions.pipeline
      result = pipeline:vPipeline
      if isString vTasks
        result.tasks = vTasks = [vTasks]
      else if isArray vTasks
        result.tasks = vTasks = vTasks.slice()
      else if isObject vTasks
        result.tasks = vTasks = extend {}, vTasks

    if vTasks
      if vPipeline
        if isArray vTasks
          # get first task
          if vTasks.length
            task = vTasks[0]
            vTasks[0] = @_initTask(task, aOptions)
        else # it's an object
          name = getKeys vTasks
          if name.length
            name = name[0]
            task = {}
            task[name] = vTasks[name]
            task = @_initTask(task, aOptions)
            vTasks[name] = task[name]
      else
        if isArray vTasks
          for task,i in vTasks
            vTasks[i] = @_initTask(task, aOptions)
        else
          for name, task of vTasks
            vTask = {}
            vTask[name] = task
            vTask = @_initTask(vTask, aOptions)
            vTasks[name] = vTask[name]
    result

  executeSync: (aOptions)->
    super @_initTasks aOptions

  execute: (aOptions, done)->
    super @_initTasks(aOptions), done
