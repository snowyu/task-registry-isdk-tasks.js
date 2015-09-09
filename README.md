## task-registry-isdk-tasks [![npm](https://img.shields.io/npm/v/task-registry-isdk-tasks.svg)](https://npmjs.org/package/task-registry-isdk-tasks)

[![Build Status](https://img.shields.io/travis/snowyu/task-registry-isdk-tasks.js/master.svg)](http://travis-ci.org/snowyu/task-registry-isdk-tasks.js)
[![Code Climate](https://codeclimate.com/github/snowyu/task-registry-isdk-tasks.js/badges/gpa.svg)](https://codeclimate.com/github/snowyu/task-registry-isdk-tasks.js)
[![Test Coverage](https://codeclimate.com/github/snowyu/task-registry-isdk-tasks.js/badges/coverage.svg)](https://codeclimate.com/github/snowyu/task-registry-isdk-tasks.js/coverage)
[![downloads](https://img.shields.io/npm/dm/task-registry-isdk-tasks.svg)](https://npmjs.org/package/task-registry-isdk-tasks)
[![license](https://img.shields.io/npm/l/task-registry-isdk-tasks.svg)](https://npmjs.org/package/task-registry-isdk-tasks)

execute sequence tasks with the aOptions of the tasks if the first task has no arguments.

* pipeline series: execute tasks with aOptions if the first task has no arguments.
* non-pipeline series: execute tasks with aOptions if the task has no arguments.

## Usage

```js
var Task = require('task-registry')
var register = Task.register
require('task-registry-isdk-tasks')

function ATask(){}
function ATask.prototype._executeSync(aOptions){
  aOptions.data++
  return aOptions
}
register ATask

function BTask(){}
function BTask.prototype._executeSync(aOptions){
  aOptions.data += 2
  return aOptions.data
}
register(BTask)

var tasks = Task('tasks')

var aObject = {data: 123, tasks: ['ATask', 'BTask']}
var result = tasks.executeSync(aObject) //result=[aOptions, 126]

aObject = {data: 123, tasks: ['ATask', 'BTask'], pipeline:true}
result = tasks.executeSync(aObject) //result=126

//the inherited options passed to 'ATask'
aObject = {data: 123, tasks: [{'ATask': {'>': {b:12}}}], pipeline:true}
result = tasks.executeSync(aObject)
Object.getPrototypeOf(result).should.be.equal aObject
result.data.should.be.equal 124
result.b.should.be.equal 12
```

## API


## TODO

## Changes


### v0.2

+ Task Options inheritence Flag: "<"

```coffee
aObject =
  data: 123
  a: 4
  tasks: [
    'ATask':
      '>':
        a:6
  , 'BTask'
  ]
result = tasks.executeSync(aObject)
```
The inherited `aObject` options should be passed to ATask and the `a` is 6 : `{a:6}`


## License

MIT
