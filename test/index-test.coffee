chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

setImmediate    = setImmediate || process.nextTick


isNumber        = require 'util-ex/lib/is/type/number'
Task            = require 'task-registry'
Tasks           = require '../src'
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
      options.data.should.be.equal 101
    it 'should run a task via task array2', ->
      result = tasks.executeSync ['Add1']
      expect(result).have.length 1
      expect(result[0]).have.property 'data', 2
    it 'should run tasks', ->
      options = data: 100, tasks:['Add1', 'Add2']
      result = tasks.executeSync options
      expect(result).have.length 2
      expect(result[0]).be.equal options
      options.data.should.be.equal 103
      options = data: 100, tasks:['Add1', {'Add2':null}]
      result = tasks.executeSync options
      expect(result).have.length 2
      expect(result[0]).be.equal options
      options.data.should.be.equal 103

      options = data: 100, tasks:['Add1', 'Add2':{data:5}]
      result = tasks.executeSync options
      expect(result).have.length 2
      expect(result[0]).be.equal options
      expect(result[1].data).be.equal 7
      options.data.should.be.equal 101

    describe 'pipeline', ->
      it 'should run a task via task name', ->
        options = data: 100, tasks:'Add1', pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        options.data.should.be.equal 101
      it 'should run a task via task array', ->
        options = data: 100, tasks:'Add1', pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        options.data.should.be.equal 101
      it 'should run tasks', ->
        options = data: 100, tasks:['Add1', 'Add2'], pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        options.data.should.be.equal 103

      it 'should run tasks obj', ->
        options = data: 100, tasks:['Add1', {'Add2':null}], pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        options.data.should.be.equal 103

      it 'should run tasks obj with non-meaning args', ->
        options = data: 100, tasks:[{'Add1':null}, 'Add2':{data:5}], pipeline:true
        result = tasks.executeSync options
        expect(result).be.equal options
        options.data.should.be.equal 103

      it 'should run tasks obj with meaning args', ->
        options = data: 100, tasks:[{'Add1':{data:10}, Add2:null}, 'Add2':{data:5}], pipeline:true
        result = tasks.executeSync options
        Add2Task::_executeSync.should.be.calledTwice
        expect(result).be.not.equal options
        result.data.should.be.equal 15

  describe '.execute', ->
    tasks = Task 'Tasks'
    it 'should run a task via task name', (done)->
      options = data: 100, tasks:'Add1'
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 1
          expect(result[0]).be.equal options
          options.data.should.be.equal 101
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
          options.data.should.be.equal 101
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
          options.data.should.be.equal 103
        done(err)

    it 'should run tasks obj', (done)->
      options = data: 100, tasks:['Add1', {'Add2':null}]
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 2
          expect(result[0]).be.equal options
          options.data.should.be.equal 103
        done(err)

    it 'should run tasks obj with non-meaning arguments', (done)->
      options = data: 100, tasks:['Add1', 'Add2':{data:5}]
      tasks.execute options, (err, result)->
        unless err
          expect(result).have.length 2
          expect(result[0]).be.equal options
          expect(result[1].data).be.equal 7
          options.data.should.be.equal 101
        done(err)

    describe 'pipeline', ->
      it 'should run a task via task name', (done)->
        options = data: 100, tasks:'Add1', pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            options.data.should.be.equal 101
          done(err)
      it 'should run a task via task array', (done)->
        options = data: 100, tasks:'Add1', pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            options.data.should.be.equal 101
          done(err)
      it 'should run tasks', (done)->
        options = data: 100, tasks:['Add1', 'Add2'], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            options.data.should.be.equal 103
          done(err)

      it 'should run tasks obj', (done)->
        options = data: 100, tasks:['Add1', {'Add2':null}], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            options.data.should.be.equal 103
          done(err)

      it 'should run tasks obj with non-meaning args', (done)->
        options = data: 100, tasks:[{'Add1':null}, 'Add2':{data:5}], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.equal options
            options.data.should.be.equal 103
          done(err)

      it 'should run tasks obj with meaning args', (done)->
        options = data: 100, tasks:[{'Add1':data:10}, 'Add2':{data:5}], pipeline:true
        tasks.execute options, (err, result)->
          unless err
            expect(result).be.not.equal options
            result.data.should.be.equal 13
          done(err)
