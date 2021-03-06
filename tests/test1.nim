# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
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

# Inversely ordered elements with pos and neg values
let lst6:seq[int] = toSeq(countdown(1000, -1000) )

# Ordered even numbers
let lst11:seq[int] = collect(newSeq):
  for i in countup(2,1000, 2):
    i
# Full of zeros
let lst12:seq[int] = collect(newSeq):
  for i in countup(1,1000 ):
    0
# Inversely ordered odd numbers
let lst13 = collect(newSeq):
  for i in countdown(9999 , 1, 2):
    i

var test_cases = @[lst1, lst2, lst3, lst4, lst5, lst6,lst11, lst12, lst13]

var test_cases_alt = @[lst1, lst2, lst3, lst4, lst5, lst6,lst11, lst12, lst13]

test "Test accuracy of algorithm":
  for lst in test_cases.mitems:
    # Make a copy of the case
    var sortable = lst

    # Make another copy of the case
    var sortable_copy = lst
    var sorted_copy = timSort2(sortable_copy)
    check sortable.len == sorted_copy.len
    check sorted_copy.isSorted
    # check sortable_copy.isSorted
    # check sorted_copy == sortable_copy

test "test sort alt":
  for lst in test_cases_alt.mitems:
    # Create a copy of the list
    var copy = lst

    timSort(copy)

    # Compare each element to the next element
    check copy.isSorted
    # Assure that the lengths are the same
    check len(copy) == len(lst)

    # Sort the copy using default
    check copy.sorted() == copy

