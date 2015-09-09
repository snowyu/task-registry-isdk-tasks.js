chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

setImmediate    = setImmediate || process.nextTick


getPrototypeOf  = require 'inherits-ex/lib/getPrototypeOf'
isNumber        = require 'util-ex/lib/is/type/number'
Tasks           = require '../src'
Task            = require('task-registry-series').super_
register        = Task.register
aliases         = Task.aliases


class ErrorTask
  register ErrorTask
  aliases ErrorTask, 'Error'

  constructor: -> return super

  _executeSync: sinon.spy (aOptions)->throw new Error 'MyError'

class Add1Task
  register Add1Task

  constructor: -> return super

  _executeSync: sinon.spy (aOptions)->
    aOptions.data = 1 unless isNumber aOptions.data
    aOptions.data++
    aOptions

class Add2Task
  register Add2Task

  constructor: -> return super

  _executeSync: sinon.spy (aOptions)->
    aOptions.data = 1 unless isNumber aOptions.data
    aOptions.data +=2
    aOptions

describe 'Tasks', ->
  beforeEach ->
    Add1Task::_executeSync.reset()
    Add2Task::_executeSync.reset()

  it 'should get tasks via aliases', ->
    tasks = Task '/Series/IsdkTasks'
    expect(tasks).be.instanceOf Tasks
    tasks = Task 'Tasks'
    expect(tasks).be.instanceOf Tasks
    tasks = Task 'tasks'
    expect(tasks).be.instanceOf Tasks

  describe '.executeSync', ->
    tasks = Task 'Tasks'
    it 'should run a task via task name', ->
      options = data: 100, tasks:'Add1'
      result = tasks.executeSync options
      expect(result).have.length 1
      expect(result[0]).be.equal options
      options.data.should.be.equal 101

    it 'should run a task via task name2', ->
      result = tasks.executeSync 'Add1'
      expect(result).have.length 1
      expect(result[0]).have.property 'data', 2
    it 'should run a task via task array', ->
      options = data: 100, tasks:['Add1']
      result = tasks.executeSync options
      expect(result).have.length 1
      expect(result[0]).be.equal options
      expect(options).be.deep.equal
        data: 101
        tasks: ['Add1']
    it 'should run a task via task array2', ->
      result = tasks.executeSync ['Add1']
      expect(result).have.length 1
      expect(result[0]).have.property 'data', 2
    it 'should run tasks', ->
      options = data: 100, tasks:['Add1', 'Add2']
      result = tasks.executeSync options
      expect(result).have.length 2
      expect(result[0]).be.equal options
      expect(options).be.deep.equal
        data: 103
        tasks: ['Add1', 'Add2']

      options = data: 100, tasks:['Add1', {'Add2':null, 'Add1':null}]
      result = tasks.executeSync options
      expect(result).have.length 3
      expect(result[0]).be.equal options
      expect(options).be.deep.equal
        data: 104
        tasks: ['Add1', {'Add2':null, 'Add1': null}]

      options = data: 100, tasks:['Add1', {'Add2':{data:5}, 'Add1':{data:2}}]
      result = tasks.executeSync options
      expect(result).have.length 3
      expect(result[0]).be.equal options
      expect(result[1].data).be.equal 7
      expect(result[2].data).be.equal 3
      expect(options).be.deep.equal
        data: 101
        tasks: ['Add1', {'Add2':{data:7}, 'Add1':{data:3}}]
    it 'should run tasks obj with inherited args', ->
      options = data: 100, tasks: {'Add1': {'<': data: 1}}
      result = tasks.executeSync options
      expect(result).to.have.length 1
      expect(getPrototypeOf result[0]).to.be.equal options
      expect(result[0].data).be.equal 2
      expect(options).be.deep.equal
        data: 100
        tasks: {'Add1': {'<': data: 1}}

    describe 'pipeline', ->
      it 'should run a task via task name', ->
        options = data: 100, tasks:'Add1', pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        expect(options).be.deep.equal
          data: 101
          tasks: 'Add1'
          pipeline:true
      it 'should run a task via task array', ->
        options = data: 100, tasks:['Add1'], pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        options.data.should.be.equal 101
        expect(options).be.deep.equal
          data: 101
          tasks: ['Add1']
          pipeline:true
      it 'should run tasks', ->
        options = data: 100, tasks:['Add1', 'Add2'], pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        expect(options).be.deep.equal
          data: 103
          tasks: ['Add1', 'Add2']
          pipeline:true

      it 'should run tasks obj', ->
        options = data: 100, tasks:['Add1', {'Add2':null, 'Add1':null}], pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        expect(options).be.deep.equal
          data: 104
          tasks: ['Add1', {'Add2':null, 'Add1':null}]
          pipeline:true

      it 'should run tasks obj with non-meaning args', ->
        options = data: 100, tasks:[{'Add1':null, 'Add2':{data:1}}, 'Add2':{data:5}], pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        expect(options).be.deep.equal
          data: 105
          tasks: [{'Add1':null, 'Add2':{data:1}}, 'Add2':{data:5}]
          pipeline:true

      it 'should run tasks obj with meaning args', ->
        options = data: 100, tasks:[{'Add1':{data:10}, Add2:null}, 'Add2':{data:5}], pipeline:true
        result = tasks.executeSync options
        Add2Task::_executeSync.should.be.calledTwice
        expect(result).be.not.equal options
        result.data.should.be.equal 15
        expect(options).be.deep.equal
          data: 100
          tasks: [{'Add1':{data:15}, Add2:null}, 'Add2':{data:5}]
          pipeline:true

      it 'should run tasks obj with inherited args', ->
        options = data: 100, tasks: {'Add1': {'<': data: 1}, 'Add2':null}, pipeline:true
        result = tasks.executeSync options
        expect(getPrototypeOf result).to.be.equal options
        expect(result.data).be.equal 4
        expect(options).be.deep.equal
          data: 100
          tasks: {'Add1': {'<': data: 1}, 'Add2':null}
          pipeline:true

  describe '.execute', ->
    tasks = Task 'Tasks'
    it 'should run a task via task name', (done)->
      options = data: 100, tasks:'Add1'
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 1
          expect(result[0]).be.equal options
          options.data.should.be.equal 101
          expect(options).be.deep.equal
            data: 101
            tasks: 'Add1'
        done(err)
    it 'should run a task via task name1', (done)->
      tasks.execute 'Add1', (err, result)->
        unless err
          expect(result).have.length 1
          expect(result[0]).have.property 'data', 2
        done(err)
    it 'should run a task via task array', (done)->
      options = data: 100, tasks:['Add1']
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 1
          expect(result[0]).be.equal options
          expect(options).be.deep.equal
            data: 101
            tasks: ['Add1']
        done(err)
    it 'should run a task via task array1', (done)->
      tasks.execute ['Add1'], (err, result)->
        unless err
          expect(result).have.length 1
          expect(result[0]).have.property 'data', 2
        done(err)
    it 'should run tasks', (done)->
      options = data: 100, tasks:['Add1', 'Add2']
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 2
          expect(result[0]).be.equal options
          expect(options).be.deep.equal
            data: 103
            tasks: ['Add1', 'Add2']
        done(err)

    it 'should run tasks obj', (done)->
      options = data: 100, tasks:['Add1', {'Add2':null, 'Add1':null}]
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 3
          expect(result[0]).be.equal options
          expect(options).be.deep.equal
            data: 104
            tasks: ['Add1', {'Add2':null, 'Add1':null}]
        done(err)

    it 'should run tasks obj with non-meaning arguments', (done)->
      options = data: 100, tasks:['Add1', {'Add2':{data:5}, 'Add1':{data:1}}]
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 3
          expect(result[0]).be.equal options
          expect(result[1].data).be.equal 7
          expect(options).be.deep.equal
            data: 101
            tasks: ['Add1', {'Add2':{data:7}, 'Add1':{data:2}}]
        done(err)
    it 'should run tasks obj with inherited args', (done)->
      options = data: 100, tasks: {'Add1': {'<': data: 1}}
      tasks.execute options, (err, result)->
        unless err
          expect(result).to.have.length 1
          expect(getPrototypeOf result[0]).to.be.equal options
          expect(result[0].data).be.equal 2
          expect(options).be.deep.equal
            data: 100
            tasks: {'Add1': {'<': data: 1}}
        done(err)

    describe 'pipeline', ->
      it 'should run a task via task name', (done)->
        options = data: 100, tasks:'Add1', pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            expect(options).be.deep.equal
              data: 101
              tasks: 'Add1'
              pipeline:true
          done(err)
      it 'should run a task via task array', (done)->
        options = data: 100, tasks:['Add1'], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            expect(options).be.deep.equal
              data: 101
              tasks: ['Add1']
              pipeline:true
          done(err)
      it 'should run tasks', (done)->
        options = data: 100, tasks:['Add1', 'Add2'], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            expect(options).be.deep.equal
              data: 103
              tasks: ['Add1', 'Add2']
              pipeline:true
          done(err)

      it 'should run tasks obj', (done)->
        options = data: 100, tasks:['Add1', {'Add2':null, 'Add1':null}], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            expect(options).be.deep.equal
              data: 104
              tasks: ['Add1', {'Add2':null, 'Add1':null}]
              pipeline:true
          done(err)

      it 'should run tasks obj with non-meaning args', (done)->
        options = data: 100, tasks:[{'Add1':null, 'Add2':{data:2}}, 'Add2':{data:5}], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            expect(options).be.deep.equal
              data: 105
              tasks: [{'Add1':null, 'Add2':{data:2}}, 'Add2':{data:5}]
              pipeline:true
          done(err)

      it 'should run tasks obj with meaning args', (done)->
        options = data: 100, tasks:[{'Add1':data:10}, 'Add2':{data:5}], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.not.equal options
            result.data.should.be.equal 13
            expect(options).be.deep.equal
              data: 100
              tasks: [{'Add1':data:13}, 'Add2':{data:5}]
              pipeline:true
          done(err)

      it 'should run tasks obj with inherited args', (done)->
        options = data: 100, tasks: {'Add1': {'<': data: 1}, 'Add2':null}, pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(getPrototypeOf result).to.be.equal options
            expect(result.data).be.equal 4
            expect(options).be.deep.equal
              data: 100
              tasks: {'Add1': {'<': data: 1}, 'Add2':null}
              pipeline:true
          done(err)
