isObject    = require 'util-ex/lib/is/type/object'
isString    = require 'util-ex/lib/is/type/string'
isArray     = require 'util-ex/lib/is/type/array'
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

  # pass the aOptions to the first task if the first has no arguments.
  _initFirstTask: (aOptions)->
    if isString aOptions
      vTasks = [aOptions]
      aOptions = tasks: vTasks
    else if isArray aOptions
      vTasks = aOptions
      aOptions = tasks: vTasks
    else if isObject aOptions
      vTasks = aOptions.tasks
      vPipeline = aOptions.pipeline
      if isString vTasks
        aOptions.tasks = vTasks = [vTasks]

    if vTasks and vTasks.length
      if vPipeline
        firstTask = vTasks[0]
        if isObject firstTask
          vName = getKeys firstTask
          if vName.length
            vName = vName[0]
            firstTask[vName] = aOptions unless firstTask[vName]?
        else if isString firstTask
          vTasks[0] = vTask = {}
          vTask[firstTask] = aOptions
      else
        for task,i in vTasks
          if isObject task
            for vName of task
              task[vName] = aOptions unless task[vName]?
          else if isString task
            vTasks[i] = vTask = {}
            vTask[task] = aOptions
    aOptions
  executeSync: (aOptions)->
    super @_initFirstTask aOptions

  execute: (aOptions, done)->
    super @_initFirstTask(aOptions), done
