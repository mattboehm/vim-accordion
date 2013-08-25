"Initialization:
"{{{
let s:accordion_running=0
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
    let s:accordion_running=1
    let direction = s:GetMovementDirection()
    "echom "direction " . direction
    if direction == "h" || direction == "l"
      let desired_viewport = s:GetDesiredViewport(size, direction)
      call s:SetViewport(desired_viewport)
    endif
    "jump to prevwin and back so that window history is preserved
    exe prevwin . " wincmd w"
    exe curwin . " wincmd w"
    let s:accordion_running=0
  endif
endfunction
"}}}
"accordion#Start(size) set global accordion size and trigger layout {{{
function! accordion#Start(size)
  let g:accordion_size = a:size
  call accordion#Accordion()
endfunction
"}}}
"accordion#StartTab(size) set tab accordion size and trigger layout {{{
function! accordion#StartTab(size)
  let t:accordion_size = a:size
  call accordion#Accordion()
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
  call accordion#Clear()
endfunction
"}}}
"accordion#Clear() undo layout {{{
function! accordion#Clear()
  let prev_running = s:accordion_running
  let s:accordion_running=1
  let curwin = winnr()
  windo call s:UnshrinkWindow()
  exe curwin . " wincmd w"
  wincmd =
  let s:accordion_running=prev_running
endfunction
"}}}
"accordion#ChangeSize(change) change number of splits (tab if set else global {{{
function! accordion#ChangeSize(change)
	if exists("t:accordion_size")
		let t:accordion_size += a:change
		call accordion#Accordion()
	elseif exists("g:accordion_size")
		let g:accordion_size += a:change
		call accordion#Accordion()
	else
		echom "Accordion can't change size; none set."
	endif
endfunction
"}}}
"Private Functions:
"s:WindowIsShrunk() returns true if current window is shrunk {{{
function! s:WindowIsShrunk()
  return &winminwidth == 0
endfunction
"}}}
"s:ShrinkWindow() shrink a window {{{
function! s:ShrinkWindow()
  setl winminwidth=0
  0 wincmd | 
  setl winfixwidth
endfunction
"}}}
"s:UnshrinkWindow() reset a window to normal {{{
function! s:UnshrinkWindow()
  setl nowinfixwidth
endfunction
"}}}
"s:GetMovementDirection() Get direction just moved when switching windows {{{
"hjkl: left/down/up/right
"x: if a window was just deleted
"?: unknown/other
"XXX: might give random answers when tabs switched
function! s:GetMovementDirection()
  let newwin = winnr()
  let prevwin = winnr("#")
  if newwin == prevwin
    return "x"
  endif
  "go to previous window
  exe prevwin . " wincmd w"
  let result = "?"
  "try moving in all 4 directions and see if you end up in the new window
  for direction in ["h", "j", "k", "l"]
    exe "wincmd " . direction
    if winnr() == newwin
      let result = direction
      break
    endif
    exe prevwin . " wincmd w"
  endfor
  exe newwin . " wincmd w"
  return result
endfunction
"}}}
"s:GetSpace(direction) return how many windows are in a direction from the current window {{{
function! s:GetSpace(direction)
    let curwin = winnr()
    let space = 0
    while space < 999
      let prevwin = winnr()
      exe "wincmd " . a:direction
      if winnr() == prevwin
        break
      endif
      let space += 1
    endwhile
    exe curwin . " wincmd w"
    return space
endfunction
"}}}
"s:GetDesiredViewport(size, direction) get the ideal viewport {{{
"size: viewport size
"direction: which direction the user just moved
function! s:GetDesiredViewport(size, direction)
  let desired_viewport = {}
  let desired_viewport[a:direction] = 0
  let desired_viewport[s:opposites[a:direction]] = a:size - 1
  return desired_viewport
endfunction
"}}}
"s:GetAdjustedViewport(desired_viewport) adjust the desired viewport {{{
"based on the available space. Perhaps it's desired to show 5 windows to the
"right, but there are only 3 to the right and many more to the left. This
"would adjut the viewport to display 3 to the right and 2 to the left
function! s:GetAdjustedViewport(desired_viewport)
  let space = {}
  let overflow = {}
  for [direction, padding] in items(a:desired_viewport)
    let space[direction] = s:GetSpace(direction)
    let ovf = padding - space[direction]
    if ovf < 0
      let ovf = 0
    endif
    let overflow[s:opposites[direction]] = ovf
    "echom "dir sp ovf" . string(direction) . string(space) . string(ovf)
  endfor
  let adjusted_viewport = {}
  for [direction, padding] in items(a:desired_viewport)
    let adjusted_viewport[direction] = min([space[direction], padding + overflow[direction]])
  endfor
  return adjusted_viewport
endfunction
"}}}
"s:SetViewport(desired_viewport) adjust the desired viewport and set it {{{
function! s:SetViewport(desired_viewport)
  "echom "sv0 ".string(winnr())
  "echom "desired:" . string(a:desired_viewport)
  let adjusted_viewport = s:GetAdjustedViewport(a:desired_viewport)
  "echom "adjusted:" . string(adjusted_viewport)
  call accordion#Clear()
  for [direction, padding] in items(adjusted_viewport)
    call s:SetViewportInDirection(direction, padding)
  endfor
  wincmd =
endfunction
"}}}
"s:SetViewportInDirection(direction, padding) unshrink/shrink windows in 1 direction {{{
"direction should be h or l for left/right
function! s:SetViewportInDirection(direction, padding)
  let curwin = winnr()
  "echom "sv1 ".string(curwin)
  "go over `padding` times in the direction
  if a:padding >= 1
    exe printf("%0.0f", a:padding) . "wincmd " . a:direction
  endif
  "go one more window over, and detect if the window number changed or
  "not
  let prevWin = winnr()
  exe "wincmd "a:direction
  while winnr() != prevWin
    call s:ShrinkWindow()
    let prevWin = winnr()
    exe "wincmd "a:direction
  endwhile
  exe curwin . " wincmd w"
endfunction
"}}}
" vim:set foldmethod=marker foldmarker={{{,}}}
