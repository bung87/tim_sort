import times
import algorithm
import tim_sort
import sugar
import random

# Even number of random ints
let lst7:seq[int] = collect( newSeq ):
  for i in countup(0, 10000,2):
    rand(-10000..10000)

# Odd number of random ints
let lst8:seq[int] = collect( newSeq ):
  for i in countup(1, 9999,2):
    rand(-10000..10000)

var timSortCosts:float

block timSort:
  var starttime =  cpuTime()
  var lst1 = lst7
  var lst2 = lst7
  for i in 0..<50:
    
    timSort(lst1)
    timSort(lst2)
  var endtime = cpuTime()
  timSortCosts = (endtime - starttime)

var algorithmCosts:float

block algorithm:
  var starttime =  cpuTime()
  var lst1 = lst7
  var lst2 = lst7
  for i in 0..<50:
    lst1.sort()
    lst2.sort()
  var endtime = cpuTime()
  algorithmCosts = (endtime - starttime)

doassert timSortCosts < algorithmCosts
echo "algorithm lib Costs(seconds):" & $algorithmCosts
echo "timSort lib Costs(seconds):" & $timSortCosts