# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
# from  tim_sort import timSort
import random
import sugar
import sequtils
import algorithm
import tim_sort

# Emtpy array
let lst1:seq[int] = @[]
# Single element
let lst2:seq[int] = @[1]
# Two elements
let lst3:seq[int] = @[1, 2]
# Alternating elements
let lst4 = @[-1,2].cycle 1000
# Ordered elements with pos and neg values
let lst5:seq[int] = toSeq(countup(-1000, 1000))
# [i for i in countup(-1000, 1000)]
# Inversely ordered elements with pos and neg values
let lst6:seq[int] = toSeq(countdown(1000, -1000) )
# Even number of random ints
let lst7:seq[int] = collect( newSeq ):
  for i in countup(1, 1000):
    rand(-10000..10000)
# [rand(-10000..10000) for i in range(1000)]
# Odd number of random ints
let lst8:seq[int] = collect( newSeq ):
  for i in countup(1, 999):
    rand(-10000..10000)
# lst8 = [random.randint(-10000, 10000) for i in range(999)]
# More alternating elements
let lst9 = @[-1,2,-3,4,5].cycle 1000
# Floats
let lst10:seq[float32] = collect(newSeq):
  for i in countup(1,10000 ):
    i.float32 + 0.2'f32
#  [(i + 0.2) for i in ]
# Ordered even numbers
let lst11:seq[int] = collect(newSeq):
  for i in countup(1,1000, 2):
    i
# Full of zeros
let lst12:seq[int] = collect(newSeq):
  for i in countup(1,1000 ):
    i
# Inversely ordered odd numbers
let lst13 = collect(newSeq):
  for i in countdown(9999 - 1, 1, 2):
    i

var test_cases = @[lst1, lst2, lst3, lst4, lst5, lst6, lst7,
              lst8, lst9,  lst11, lst12, lst13]

var test_cases_alt = @[lst1, lst2, lst3, lst4, lst5, lst6, lst7,
              lst8, lst9,  lst11, lst12, lst13]

test "Test accuracy of algorithm":
  for lst in test_cases:
    # Make a copy of the case
    var sortable = lst

    # Make another copy of the case
    var sortable_copy = lst
    var sorted_copy = timSort(sortable_copy)

    check sorted_copy == sortable_copy
    check sorted_copy == sorted(sortable)


test "test sort alt":
  for lst in test_cases_alt.mitems:
    # Create a copy of the list
    var copy = lst

    discard timSort(lst)
    # Compare each element to the next element
    for i in countup(1,len(lst)):
        check lst[i] <= lst[i + 1]

    # Assure that the lengths are the same
    check len(copy) == len(lst)

    # Sort the copy using default
    copy.sort()

    # Every element in lst is in copy
    for i in countup(1,len(lst)):
        check copy[i] == lst[i]
