# Took inspiration from Tim Peter's original explanation,
# https://github.com/python/cpython/blob/master/Objects/listsort.txt


const MIN_MERGE = 32
const MIN_GALLOP = 7

type Run = tuple
  start:int
  ed:int
  ltr:bool
  length:int

iterator pyRange*( start = 0, stop = -1, step = 1): int =
  assert step != 0
  var
    i = min(start,stop)
    stop = max(start,stop)
  if step >= 1:
    while i <= stop:
      yield i
      i += step
  else:
    while stop > i:
      yield stop
      stop += step

proc reverseRange[T](lst:var openArray[T], s, e:int) =
    ## Reverse the order of a list in place
    ## Input: s = starting index, e = ending index"""
    var 
      s = s
      e = e
    while s < e:
      swap(lst[s], lst[e])
      s += 1
      e -= 1

func mergeComputeMinRun(n:int): int= 
  assert n >= 0
  var r = 0
  var nn = n
  while nn >= MIN_MERGE:
    r = r or (nn and 1)
    nn = nn shr 1
  result = nn + r

func countRun[T](lst:sink openArray[T],sRun:int): Run =
  var increasing = true
  var eRun:int
  if sRun == lst.len - 1:
    return (sRun,sRun,increasing,1)
  else:
    eRun = sRun
    if lst[sRun] > lst[sRun + 1]:
      while lst[eRun] > lst[eRun + 1]:
        eRun += 1
        if eRun == lst.len - 1:
          break
      increasing = false
      return (sRun,eRun,increasing,eRun - sRun + 1)
    else:
      while lst[eRun] <= lst[eRun + 1]:
        eRun += 1
        if eRun == lst.len - 1:
          break
      return (sRun,eRun,increasing,eRun - sRun + 1)

proc binSort[T](lst:var openArray[T];s,e,extend:int) = 
  var pos,start,ed,mid:int
  var value:T
  for i in countup(1,extend ):
    pos = 0
    start = s
    ed = e + i
    value = lst[ed]
    if value >= lst[ed - 1]:
      continue
    while start <= ed:
      if start == ed:
        if lst[start] > value:
          pos = start
          break
        else:
          pos = start + 1
          break
      mid = (start + ed) div 2
      if value >= lst[mid]:
        start = mid + 1
      else:
        ed = mid - 1
    if start > ed:
      pos = start
    for x in pyRange(e + i , pos,-1):
      lst[x] = lst[x - 1]
    lst[pos] = value

proc bisectRight[T](a: openArray[T]; x:T, lo:int=0, hi:int= -1):int = 
  ## Return the index where to insert item x in list a, assuming a is sorted.
  ## The return value i is such that all e in a[:i] have e <= x, and all e in
  ## a[i:] have e > x.  So if x already appears in the list, a.insert(x) will
  ## insert just after the rightmost x already there.
  ## Optional args lo (default 0) and hi (default len(a)) bound the
  ## slice of a to be searched.

  var
    lo = lo
    hi = hi
    mid:int
  if lo < 0:
    raise newException(ValueError, "lo must be non-negative")
  if hi == -1:
      hi = len(a)
  while lo < hi:
    mid = (lo + hi) div 2
    # Use __lt__ to match the logic in list.sort() and in heapq
    if x < a[mid]: hi = mid
    else: lo = mid + 1
  return lo

proc bisectLeft[T](a: openArray[T]; x: T; lo: int = 0, hi: int = -1): int =
  # Return the index where to insert item x in list a, assuming a is sorted.
  # The return value i is such that all e in a[:i] have e < x, and all e in
  # a[i:] have e >= x.  So if x already appears in the list, a.insert(x) will
  # insert just before the leftmost x already there.
  # Optional args lo (default 0) and hi (default len(a)) bound the
  # slice of a to be searched.
  var
    lo = lo
    hi = hi
    mid:int
  if lo < 0:
    raise newException(ValueError, "lo must be non-negative")
  if hi == -1:
    hi = a.len
  while lo < hi:
    mid = (lo + hi) div 2
    if a[mid] < x:
      lo = mid + 1
    else:
      hi = mid
  return lo

proc gallop[T](lst:var openArray[T];val:T;ll,hh:int;ltr:bool):int =
  ## Find the index of val in the slice[low:high]
  if ltr == true:
    result = bisectLeft(lst, val, ll, hh)
  else:
    result = bisectRight(lst, val, ll, hh)

proc mergeHigh[T](lst: var openArray[T], a:Run, b:Run, min_gallop:int)
proc mergeLow[T](lst: var openArray[T], a:Run, b:Run, min_gallop:int)

proc merge[T](lst:var openArray[T],stack:var seq[Run],runNum:int) = 
  let index = if runNum < 0: stack.len + runNum else: runNum
  # Make references to the to-be-merged runs
  var 
    runA = stack[index]
    runB = stack[index + 1]
  stack[index] = (run_a[0], run_b[1], true, run_b[1] - run_a[0] + 1)
  stack.delete index + 1
  if runA[3] <= runB[3]:
    mergeLow(lst,runA,runB,MIN_GALLOP)
  else:
    mergeHigh(lst,runA,runB,MIN_GALLOP)

proc mergeLow[T](lst:var openArray[T], a:Run, b:Run, min_gallop:int) = 
  ## Merges the two runs quasi in-place if a is the smaller run
  ## - a and b are lists that store data of runs
  ## - min_gallop: threshold needed to switch to galloping mode
  ## - galloping mode: uses gallop() to 'skip' elements instead of linear merge"""

  # Make a copy of the run a, the smaller run
  var temp_array = lst[ a[0] .. a[1]] # makeTempArray(lst, a[0], a[1])
  # The first index of the merging area
  var k = a[0]
  # Counter for the temp array of a
  var i = 0
  # Counter for b, starts at the beginning
  var j = b[0]

  var gallop_thresh = min_gallop
  var a_count = 0  # number of times a win in a row
  var b_count = 0  # number of times b win in a row
  var a_adv,b_adv:int
  while true:
    a_count = 0
    b_count = 0

    # Linear merge mode, taking note of how many times a and b wins in a row.
    # If a_count or b_count > threshold, switch to gallop
    while i <= len(temp_array) - 1 and j <= b[1]:
      # if elem in a is smaller, a wins
      if temp_array[i] <= lst[j]:
        lst[k] = temp_array[i]
        k += 1
        i += 1

        a_count += 1
        b_count = 0

        # If a runs out during linear merge
        # Copy the rest of b
        if i > len(temp_array) - 1:
          while j <= b[1]:
            lst[k] = lst[j]
            k += 1
            j += 1
          return

        # threshold reached, switch to gallop
        if a_count >= gallop_thresh:
          break
      # if elem in b is smaller, b wins
      else:
        lst[k] = lst[j]
        k += 1
        j += 1

        a_count = 0
        b_count += 1

        # If b runs out during linear merge
        # copy the rest of a
        if j > b[1]:
          while i <= len(temp_array) - 1:
            lst[k] = temp_array[i]
            k += 1
            i += 1
          return

        # threshold reached, switch to gallop
        if b_count >= gallop_thresh:
          break

    # If one run is winning consistently, switch to galloping mode.
    # i, j, and k are incremented accordingly
    
    while true:
      # Look for the position of b[j] in a
      # bisect_left() -> a_adv = index in the slice [i: len(temp_array)]
      # so that every elem before temp_array[a_adv] is strictly smaller than lst[j]
      a_adv = gallop(temp_array, lst[j], i, len(temp_array), true)

      # Copy the elements prior to a_adv to the merge area, increment k
      for x in i ..< a_adv:
        lst[k] = temp_array[x]
        k += 1

      # Update the a_count to check successfulness of galloping
      a_count = a_adv - i

      # Advance i to a_adv
      i = a_adv

      # If run a runs out
      if i > len(temp_array) - 1:
        # Copy all of b over, if there is any left
        while j <= b[1]:
          lst[k] = lst[j]
          k += 1
          j += 1
        return

      # Copy b[j] over
      lst[k] = lst[j]
      k += 1
      j += 1

      # If b runs out
      if j > b[1]:
        # Copy all of a over, if there is any left
        while i < len(temp_array):
          lst[k] = temp_array[i]
          k += 1
          i += 1
        return

        # ------------------------------------------------------

      # Look for the position of a[i] in b
      # b_adv is analogous to a_adv
      b_adv = gallop(lst, temp_array[i], j, b[1] + 1, true)
      for y in j ..< b_adv:
        lst[k] = lst[y]
        k += 1

      # Update the counters and check the conditions
      b_count = b_adv - j
      j = b_adv

      # If b runs out
      if j > b[1]:
        # copy the rest of a over
        while i <= len(temp_array) - 1:
          lst[k] = temp_array[i]
          k += 1
          i += 1
        return

      # copy a[i] over to the merge area
      lst[k] = temp_array[i]
      i += 1
      k += 1

      # If a runs out
      if i > len(temp_array) - 1:
        # copy the rest of b over
        while j <= b[1]:
          lst[k] = lst[j]
          k += 1
          j += 1
        return

      # if galloping proves to be unsuccessful, return to linear
      if a_count < gallop_thresh and b_count < gallop_thresh:
        break

    # punishment for leaving galloping
    # makes it harder to enter galloping next time
    gallop_thresh += 1


proc mergeHigh[T](lst:var openArray[T], a:Run, b:Run, min_gallop:int) =
  ## Merges the two runs quasi in-place if b is the smaller run
  ## - Analogous to merge_low, but starts from the end
  ## - a and b are lists that store data of runs
  ## - min_gallop: threshold needed to switch to galloping mode
  ## - galloping mode: uses gallop() to 'skip' elements instead of linear merge"""

  # Make a copy of b, the smaller run
  var temp_array = lst[ b[0] .. b[1]]# makeTempArray(lst, b[0], b[1])

  # Counter for the merge area, starts at the last index of array b
  var k = b[1]
  # Counter for the temp array
  var i = b[1] - b[0]  # Lower bound is 0

  # Counter for a, starts at the end this time
  var j = a[1]

  var gallop_thresh = min_gallop
  var a_adv:int
  var b_adv:int
  var a_count = 0  # number of times a win in a row
  var b_count = 0  # number of times b win in a row
  while true:
    # Linear merge, taking note of how many times a and b wins in a row.
    # If a_count or b_count > threshold, switch to gallop
    while i >= 0 and j >= a[0]:
      if temp_array[i] > lst[j]:
        lst[k] = temp_array[i]
        k -= 1
        i -= 1

        a_count = 0
        b_count += 1

        # If b runs out during linear merge
        if i < 0:
          while j >= a[0]:
            lst[k] = lst[j]
            k -= 1
            j -= 1
          return

        if b_count >= gallop_thresh:
          break

      else:
        lst[k] = lst[j]
        k -= 1
        j -= 1

        a_count += 1
        b_count = 0

        # If a runs out during linear merge
        if j < a[0]:
          while i >= 0:
            lst[k] = temp_array[i]
            k -= 1
            i -= 1
          return

        if a_count >= gallop_thresh:
          break

    # i, j, k are DECREMENTED in this case
    
    while true:
      # Look for the position of b[i] in a[0, j + 1]
      # ltr = False -> uses bisect_right()
      a_adv = gallop(lst, temp_array[i], a[0], j + 1, false)

      # Copy the elements from a_adv -> j to merge area
      # Go backwards to the index a_adv
      for x in pyRange(j , a_adv - 1,-1):
          lst[k] = lst[x]
          k -= 1

      # # Update the a_count to check successfulness of galloping
      a_count = j - a_adv + 1

      # Decrement index j
      j = a_adv - 1

      # If run a runs out:
      if j < a[0]:
        while i >= 0:
          lst[k] = temp_array[i]
          k -= 1
          i -= 1
        return

      # Copy the b[i] into the merge area
      lst[k] = temp_array[i]
      k -= 1
      i -= 1

      # If a runs out:
      if i < 0:
        while j >= a[0]:
          lst[k] = lst[j]
          k -= 1
          j -= 1
        return

      # Look for the position of A[j] in B:
      b_adv = gallop(temp_array, lst[j], 0, i + 1, false)
      for y in pyRange(i , b_adv - 1,-1):
        lst[k] = temp_array[y]
        k -= 1

      b_count = i - b_adv + 1
      i = b_adv - 1

      # If b runs out:
      if i < 0:
        while j >= a[0]:
          lst[k] = lst[j]
          k -= 1
          j -= 1
        return

      # Copy the a[j] back to the merge area
      lst[k] = lst[j]
      k -= 1
      j -= 1

      # If a runs out:
      if j < a[0]:
        while i >= 0:
          lst[k] = temp_array[i]
          k -= 1
          i -= 1
        return

      # if galloping proves to be unsuccessful, return to linear
      if a_count < gallop_thresh and b_count < gallop_thresh:
        break

    # punishment for leaving galloping
    gallop_thresh += 1

proc mergeCollapse[T](lst:var openArray[T], stack:var seq[Run]) =
  ## The last three runs in the stack is A, B, C.
  ## Maintains invariants so that their lengths: A > B + C, B > C
  ## Translated to stack positions:
  ##    stack[-3] > stack[-2] + stack[-1]
  ##    stack[-2] > stack[-1]
  ## Takes a stack that holds many lists of type [s, e, bool, length]"""

  # This loops keeps running until stack has one element
  # or the invariant holds.
  while len(stack) > 1:
    if len(stack) >= 3 and stack[^3][3] <= stack[^2][3] + stack[^1][3]:
      if stack[^3][3] < stack[^1][3]:
        # merge -3 and -2, merge at -3
        merge(lst, stack, -3)
      else:
        # merge -2 and -1, merge at -2
        merge(lst, stack, -2)
    elif stack[^2][3] <= stack[^1][3]:
      # merge -2 and -1, merge at -2
      merge(lst, stack, -2)
    else:
      break


proc mergeForceCollapse[T](lst:var openArray[T], stack:var seq[Run]) =
  ## When the invariant holds and there are > 1 run
  ## in the stack, this function finishes the merging"""
  while len(stack) > 1:
    # Only merges at -2, because when the invariant holds,
    # merging would be balanced
    merge(lst, stack, -2)

proc timSort*[T](lst: var openArray[T]) = 
  # compare:proc (a: T, b: T) :int
  # Starting index
  var s = 0
  # Ending index
  var e = len(lst) - 1
  # The stack
  var stack:seq[Run] = @[]
  # Compute min_run using size of lst
  var min_run = mergeComputeMinrun(len(lst))
  var run: Run
  var extend:int
  while s <= e:
    # Find a run, return [start, end, bool, length]
    run = countRun(lst, s)

    # If decreasing, reverse
    if run[2] == false:
      reverseRange(lst, run[0], run[1])
      # Change bool to True
      run[2] = true

    # If length of the run is less than min_run
    if run[3] < min_run:
      # The number of indices by which we want to extend the run
      # either by the distance to the end of the lst
      # or by the length difference between run and minrun
      extend = min(min_run - run[3], e - run[1])

      # Extend the run using binary insertion sort
      binSort(lst, run[0], run[1], extend)

      # Update last index of the run
      run[1] = run[1] + extend

      # Update the run length
      run[3] = run[3] + extend

    # Push the run into the stack
    stack.add(run)

    # Start merging to maintain the invariant
    mergeCollapse(lst, stack)

    # Update starting position to find the next run
    # If run[1] == end of the lst, s > e, loop exits
    s = run[1] + 1

  # Some runs might be left in the stack, complete the merging.
  mergeForceCollapse(lst, stack)

  # # Return the lst, ta-da.
  # result = @lst

proc timSort2*[T](lst: openArray[T]):seq[T] = 
  result = @lst
  timSort(result)