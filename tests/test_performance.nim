import std/[times, algorithm, random, sugar, stats, monotimes]
import tim_sort

# Even number of random ints
let lst7:seq[int] = collect( newSeq ):
  for i in countup(0, 10000,2):
    rand(-10000..10000)

# Odd number of random ints
let lst8:seq[int] = collect( newSeq ):
  for i in countup(1, 9999,2):
    rand(-10000..10000)

const IterCount = 500
var timSortStat: RunningStat

block timSort:
  for i in 0 ..< IterCount:
    var lst1 = lst7
    var lst2 = lst7
    let curTime = getMonoTime()
    timSort(lst1)
    timSort(lst2)
    timSortStat.push float((getMonoTime() - curTime).inMicroseconds)

var algoSortStat: RunningStat

block algorithm:
  for i in 0 ..< IterCount:
    var lst1 = lst7
    var lst2 = lst7
    let curTime = getMonoTime()
    lst1.sort()
    lst2.sort()
    algoSortStat.push float((getMonoTime() - curTime).inMicroseconds)

echo "Algorithm ", algoSortStat
echo "TimSort ", timSortStat
doAssert timSortStat.mean < algoSortStat.mean