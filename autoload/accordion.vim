"s:accordion_running: true if accordion is currently changing the layout {{{
  "normally, accordion is triggered by the user changing windows
  "we don't want to trigger it if accordion itself caused the change
  let s:accordion_running = 0
"}}}
"s:accordion_clearing: true if accordionClear() is currently running {{{
  "needed so that diffmode does not try to diff visible windows while accordion
  "is clearing.
  let s:accordion_clearing = 0
"}}}
"s:opposites: a mapping of directions to their opposites {{{
  let s:opposites = {"h": "l", "l": "h", "j": "k", "k": "j"}
"}}}
"Exposed Functions:
"accordion#Accordion(size) do layout. Shrink excess splits {{{
"size defaults to tab/global setting
function! accordion#Accordion(...)
  let curwin = winnr()
  let prevwin = winnr("#")
  let size = 0
  if a:0 == 0
    if exists("t:accordion_size")
      let size = t:accordion_size
    elseif exists("g:accordion_size")
      let size = g:accordion_size
    endif
  else
    let size = a:1
  endif
  "accordion can be triggered on the change of window focus
  "this is a hack so accordion doesn't recursively trigger itself
  if !s:accordion_running && size > 0
    let s:accordion_running = 1
    let direction = s:GetMovementDirection()
    "echom "direction " . string(direction)
    let desired_viewport = s:GetDesiredViewport(size, direction)
    if len(desired_viewport)
      call s:SetViewport(desired_viewport)
    endif
    "jump to prevwin and back so that window history is preserved
    execute prevwin "wincmd w"
    execute curwin "wincmd w"
    let s:accordion_running = 0
  endif
endfunction
"}}}
"accordion#Start(size) set global accordion size and trigger layout {{{
function! accordion#Start(size)
  call s:SetSize(g:, a:size)
  call accordion#Accordion()
endfunction
"}}}
"accordion#StartTab(size) set tab accordion size and trigger layout {{{
function! accordion#StartTab(size)
  call s:SetSize(t:, a:size)
  call accordion#Accordion()
endfunction
"}}}
"accordion#Diff() run accordion in diff mode (size 2, visible windows diffed) {{{
function! accordion#Diff()
  let t:accordion_diff = 1
  call accordion#StartTab(2)
endfunction
"}}}
"accordion#Stop() Turn off accordion and reset layout {{{
function! accordion#Stop()
  "unlock window widths
  "TODO only unshrinks this tab, so if a global option was set, other
  "tabs might be accordioned still.
  if exists("t:accordion_size")
    unlet t:accordion_size
  elseif exists("g:accordion_size")
    unlet g:accordion_size
  endif
  unlet! t:accordion_diff
  unlet! t:accordion_last_desired_viewport
  call accordion#Clear()
endfunction
"}}}
"accordion#Clear() undo layout {{{
function! accordion#Clear()
  "set accordion_running and accordion_clearing to 1 {{{
  let prev_running = s:accordion_running
  let s:accordion_running = 1
  let s:accordion_clearing = 1
  "}}}
  "save window position
  let curwin = winnr()
  "unshrink all the windows
  windo call s:UnshrinkWindow()
  execute curwin "wincmd w"
  wincmd =
  call s:RestoreVisibleWindowViews()
  let s:accordion_clearing = 0
  let s:accordion_running = prev_running
endfunction
"}}}
"accordion#ChangeSize(change) change number of splits (tab if set else global {{{
function! accordion#ChangeSize(change)
  "change tab variable if it exists
  if exists("t:accordion_size")
    if t:accordion_size + a:change >= 1
      call s:SetSize(t:, t:accordion_size + a:change)
      call accordion#Accordion()
    else
      echoerr "Accordion size can't be less than 1"
    endif
  "else change global if it exists
  elseif exists("g:accordion_size")
    if g:accordion_size + a:change >= 1
      call s:SetSize(g:, g:accordion_size + a:change)
      let g:accordion_size += a:change
      call accordion#Accordion()
    else
      echoerr "Accordion size can't be less than 1"
    endif
  "no tab or global setting to change
  else
    echom "Accordion can't change size; none set."
  endif
endfunction
"}}}
"accordion#Pause() prevent accordion from running {{{
function! accordion#Pause()
  let s:accordion_running = 1
endfunction
"}}}
"accordion#Unpause() undo pause, allowing accordion to run {{{
function! accordion#Unpause()
  let s:accordion_running = 0
endfunction
"}}}
"Helpers:
"s:SetSize(ns, size) set global or tab size. If already set, also mark g:accordion_size_changed {{{
"If accordion was running and the user called it again with a different size,
"we need to re-layout.
function! s:SetSize(ns, size)
  if get(a:ns, "accordion_size")
    let g:accordion_size_changed=1
  endif
  let a:ns["accordion_size"]=a:size
endfunction
"}}}
"Shrinking:
"s:WindowIsShrunk() returns true if current window is shrunk {{{
function! s:WindowIsShrunk()
  return &winfixwidth
endfunction
"}}}
"s:ShrinkWindow() shrink a window {{{
function! s:ShrinkWindow()
  "save the viewport before shrinking as shrinking can mess up window position
  if !exists("w:accordion_view")
    let w:accordion_view=winsaveview()
  endif
  setl winminwidth=0
  0 wincmd | 
  setl winfixwidth
  "if in diff mode, shrunk windows are not diffed
  if exists("t:accordion_diff")
    diffoff
  endif
endfunction
"}}}
"s:UnshrinkWindow() reset a window to normal {{{
function! s:UnshrinkWindow()
  setl nowinfixwidth
  "if in diff mode, diff unshrunk windows,
  "but not if UnshrinkWindow was called by AccordionClear()
  if exists("t:accordion_diff") && !s:accordion_clearing
    diffthis
  endif
endfunction
"}}}
"s:RestoreVisibleWindowViews() restore all visible windows' dimensions {{{
function! s:RestoreVisibleWindowViews()
  windo if !s:WindowIsShrunk() | call s:RestoreCurrentWindowView() | endif
endfunction
"}}}
"s:RestoreCurrentWindowView() restore the current window's dimensions {{{
"XXX: clears the view variable after restoring
function! s:RestoreCurrentWindowView()
  if exists("w:accordion_view")
    call winrestview(w:accordion_view)
    unlet w:accordion_view
  endif
endfunction
"}}}
"Calculate Viewport:
"s:GetMovementDirection() Get direction just moved when switching windows {{{
"hjkl: left/down/up/right
"x: if a window was just deleted
"?: unknown/other
"XXX: might give random answers when tabs switched
function! s:GetMovementDirection()
  let newwin = winnr()
  let prevwin = winnr("#")
  "since buffer numbers always increase from up to down and left to right,
  "we know that if the buffer number has increased since the last move,
  "the direction must be down or right
  if newwin == prevwin
    return {"direction": "x"}
  elseif newwin < prevwin
    let possible_directions = ["h", "k"]
  else "newwin > prevwin
    let possible_directions = ["l", "j"]
  endif
  "go to previous window
  execute prevwin "wincmd w"
  let result = {"direction": "?"}
  "try moving in all 4 directions and see if you end up in the new window
  for direction in possible_directions
    let num_movements = s:GetNumMovementsInDirection(newwin, direction)
    if num_movements != -1
      let result = {"direction": direction, "magnitude": num_movements}
      break
    endif
  endfor
  execute newwin "wincmd w"
  return result
endfunction
"}}}
"s:GetNumMovementsInDirection(target, direction) return how many times you {{{
"have to move in `direction` to reach `target`. Return -1 if wrong direction
function! s:GetNumMovementsInDirection(target, direction)
  let start = winnr()
  let current = start
  "the maximum number of movements we have to try. this works because buffers
  "are numbered sequentially
  let max_distance = abs(start - a:target)
  let num_movements = 0
  "set to true if we couldn't find the window in that direction
  let aborted = 0
  while current != a:target
    exe "wincmd" a:direction
    let num_movements += 1
    let previous = current
    let current = winnr()
    "return if no more windows in this direction
    "return if we've gone farther than the max distance
    if current == previous || abs(start - current) > max_distance
      let aborted = 1
      break
    endif
  endwhile
  "go back to the start window so that this function has no side effects
  execute start "wincmd w"
  if aborted
    return -1
  else
    return num_movements
  endif
endfunction
"}}}
"s:GetSpace(direction) return how many windows are in a direction from the current window {{{
function! s:GetSpace(direction)
  "save the current window so we can go back to it later
  let curwin = winnr()
  let space = 0
  while space < 999
    let prevwin = winnr()
    "try to go one window over
    execute "wincmd" a:direction
    "if we're not in a new window, there are no more windows in the direction
    if winnr() == prevwin
      break
    endif
    let space += 1
  endwhile
  "go back to the initial window
  execute curwin "wincmd w"
  return space
endfunction
"}}}
"s:GetViewportSize(viewport) get the # of unshrunk windows in the viewport {{{
function! s:GetViewportSize(viewport)
  return a:viewport["h"] + a:viewport["l"] + 1
endfunction
"}}}
"s:SetViewportSize(viewport, size) adjusts viewport to the desired size {{{
"does this by adding/removing windows to the right side
function! s:SetViewportSize(viewport, size)
  "get the current size of the viewport
  let current_size = s:GetViewportSize(a:viewport)
  "copy the viewport so we don't modify the original
  let resized_viewport = copy(a:viewport)
  "note: windows_to_add could be negative if we need to remove windows
  let windows_to_add = a:size - current_size
  let resized_viewport["l"] += windows_to_add
  "if it was negative, it's possible that this direction is now < 0
  "move these excess subtractions to the other side
  if resized_viewport["l"] < 0
    let resized_viewport["h"] += resized_viewport["l"]
    let resized_viewport["l"] = 0
  endif
  return resized_viewport
endfunction
"}}}
"s:GetDesiredViewport(size, direction) get the ideal viewport {{{
"size: viewport size
"direction: which direction the user just moved
function! s:GetDesiredViewport(size, direction)
  let desired_viewport = {}
  let resized_viewport = {}
  let should_redraw = 1
  let dir = a:direction["direction"]
  let magnitude = get(a:direction, "magnitude")
  if exists("g:accordion_size_changed")
    let size_changed = 1
    let dir = "h"
    let magnitude = 0
    unlet g:accordion_size_changed
  else
    let size_changed = 0
  endif
  "initially set viewport to show windows to the right of curwin
  if !exists("t:accordion_last_desired_viewport")
    let desired_viewport["h"] = 0
    let desired_viewport["l"] = a:size - 1
  "if the last motion was up/down or a window was just deleted, use the same
  "viewport as last time
  elseif dir == "u" || dir == "d" || dir == "x"
    let desired_viewport = t:accordion_last_desired_viewport
  "if the last motion was left/right, adjust the viewport so it looks the same
  "to the user.
  elseif dir == "h" || dir == "l"
    let desired_viewport = t:accordion_last_desired_viewport
    let desired_viewport[dir] = 
      \ max([desired_viewport[dir] - magnitude, 0])
    let desired_viewport[s:opposites[dir]] = 
      \ min([desired_viewport[s:opposites[dir]] + magnitude, a:size - 1])
    "if the current window's not shrunk, there's no need to redraw
    "we skip redrawing to be more efficient and to let users resize the
    "visible splits
    "If the user's just called :vsp and added a new window, we still need to
    "redraw
    if !s:WindowIsShrunk() && winnr("$") == get(t:, "accordion_num_windows") && !size_changed
      let should_redraw = 0
    endif
  endif
  if len(desired_viewport)
    "if the size has changed since the last run, we need to adjust the desired viewport
    let resized_viewport = s:SetViewportSize(desired_viewport, a:size)
    "if the viewport size has changed, we should redraw no matter what
    if resized_viewport != desired_viewport
      let should_redraw = 1
    endif
    "save the viewport so that we can refer to it the next time.
    let t:accordion_last_desired_viewport = resized_viewport
    if !should_redraw
      let resized_viewport = {}
    endif
  endif
  let t:accordion_num_windows = winnr("$")
  return resized_viewport
endfunction
"}}}
"s:GetAdjustedViewport(desired_viewport) adjust the desired viewport {{{
"based on the available space. Perhaps it's desired to show 5 windows to the
"right, but there are only 3 to the right and many more to the left. This
"would adjut the viewport to display 3 to the right and 2 to the left
function! s:GetAdjustedViewport(desired_viewport)
  let space = {}
  let overflow = {}
  "calculate space/overflow. if desired viewport is 3 to the right, but there is
  "only 1 window to the right, the space for the right side is 1 and the overflow for the LEFT is 2 (3 - 1)
  for [direction, padding] in items(a:desired_viewport)
    let space[direction] = s:GetSpace(direction)
    let ovf = padding - space[direction]
    if ovf < 0
      let ovf = 0
    endif
    let overflow[s:opposites[direction]] = ovf
  endfor
  let adjusted_viewport = {}
  "padding for a direction = actual padding + overflow (from other direction)
  "but cannot exceed the actual space.
  for [direction, padding] in items(a:desired_viewport)
    let adjusted_viewport[direction] = min([space[direction], padding + overflow[direction]])
  endfor
  return adjusted_viewport
endfunction
"}}}
"Set Viewport:
"s:SetViewport(desired_viewport) adjust the desired viewport and set it {{{
function! s:SetViewport(desired_viewport)
  "set lazyredraw so that vim doesn't render windows while we're resizing them
  let oldlazyredraw = &lazyredraw
  set lazyredraw
  let adjusted_viewport = s:GetAdjustedViewport(a:desired_viewport)
  for [direction, padding] in items(adjusted_viewport)
    call s:SetViewportInDirection(direction, padding)
  endfor
  wincmd =
  call s:RestoreVisibleWindowViews()
  let &lazyredraw = oldlazyredraw
endfunction
"}}}
"s:SetViewportInDirection(direction, padding) unshrink/shrink windows in 1 direction {{{
"direction should be h or l for left/right
function! s:SetViewportInDirection(direction, padding)
  let curwin = winnr()
  "unshrink the current window and `padding` windows in `direction`
  let padding = a:padding
  while padding >= 0
    "FIXME: current window gets unshrunk for each direction. Not currently an
    "issue, but may become one.
    call s:UnshrinkWindow()
    let prevWin = winnr()
    execute "wincmd" a:direction
    let padding -= 1
  endwhile
  "since the above loop unshrinks and then moves, we should now be on the
  "first window to shrink, unless there are no more windows.
  "while there's still a new window under the cursor, shrink the window and
  "move again.
  while winnr() != prevWin
    call s:ShrinkWindow()
    let prevWin = winnr()
    execute "wincmd" a:direction
  endwhile
  "go back to the initial window
  execute curwin "wincmd w"
endfunction
"}}}
" vim: et sw=2 sts=2 foldmethod=marker foldmarker={{{,}}}
