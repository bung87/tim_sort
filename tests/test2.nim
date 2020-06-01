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

# Even number of random ints
let lst7:seq[int] = collect( newSeq ):
  for i in countup(1, 1000):
    rand(-10000..10000)

# Odd number of random ints
let lst8:seq[int] = collect( newSeq ):
  for i in countup(1, 999):
    rand(-10000..10000)

# More alternating elements
let lst9 = @[-1,2,-3,4,5].cycle 1000
# Floats
let lst10:seq[float32] = collect(newSeq):
  for i in countup(1,10000 ):
    i.float32 + 0.2'f32

var test_cases = @[lst7,lst8, lst9]

var test_cases_alt = @[lst7,lst8, lst9]

test "Test accuracy of algorithm":
  for lst in test_cases.mitems:
    # Make a copy of the case
    var sortable = lst

    # Make another copy of the case
    var sortable_copy = lst
    var sorted_copy = timSort(sortable_copy)
    check sortable.len == sorted_copy.len
    check sorted_copy.isSorted
    check sortable_copy.isSorted
    # check sorted_copy == sortable_copy

test "test sort alt":
  for lst in test_cases_alt.mitems:
    # Create a copy of the list
    var copy = lst

    discard timSort(copy)

    # Compare each element to the next element
    check copy.isSorted
    # Assure that the lengths are the same
    check len(copy) == len(lst)

    # Sort the copy using default
    # check lst.sorted() == copy
