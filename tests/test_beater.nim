import unittest
import times, options, asyncdispatch
import schedules

proc dummyAsync(): Future[void] {.async.} = discard

test "IntervalBeater.$":
  let beater = initBeater(initTimeInterval(seconds=1), dummyAsync)
  check $beater == "Beater(bkInterval,1 second)"

test "IntervalBeater.fireTime | startTime hasn't come":
  let current = now().utc()
  let beater = initBeater(
    initTimeInterval(seconds=10),
    dummyAsync,
    startTime=some(current + initTimeInterval(seconds=4))
  )
  let expect = current + initTimeInterval(seconds=4)
  let actual = beater.fireTime(none(DateTime), current).get()
  check actual == expect

test "IntervalBeater.fireTime | startTime has come":
  let current = now().utc()
  let beater = initBeater(
    initTimeInterval(seconds=10),
    dummyAsync,
    startTime=some(current - initTimeInterval(seconds=14))
  )
  let expect = current + initTimeInterval(seconds=6)
  let actual = beater.fireTime(none(DateTime), current).get()
  check actual == expect

test "IntervalBeater.fireTime | startTime has come 2":
  let current = now().utc()
  let beater = initBeater(
    initTimeInterval(seconds=10),
    dummyAsync,
    startTime=some(current - initTimeInterval(seconds=4))
  )
  let expect = current + initTimeInterval(seconds=6)
  let actual = beater.fireTime(none(DateTime), current).get()
  check actual == expect

test "IntervalBeater.fireTime | some prev":
  let current = now().utc()
  let beater = initBeater(initTimeInterval(seconds=10), dummyAsync)
  let prev = some(current - initTimeInterval(seconds=4))
  let actual = beater.fireTime(prev, current).get()
  let expect = current + initTimeInterval(seconds=6)
  check actual == expect
