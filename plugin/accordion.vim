let s:accordion_running=0
let s:opposites = {"h": "l", "l": "h", "j": "k", "k": "j"}

if !exists("g:accordion_listening")
  let g:accordion_listening = 1
endif

if g:accordion_listening
  augroup accordion
    autocmd!
    autocmd WinEnter * call Accordion()
  augroup end
else
  augroup accordion
    autocmd!
  augroup end
endif

function! AccordionStop()
  "unlock window widths
  "TODO only unshrinks this tab, so if a global option was set, other
  "tabs might be accordioned still.
  if exists("t:accordion_size")
    unlet t:accordion_size
  elseif exists("g:accordion_size")
    unlet g:accordion_size
  endif
  call AccordionClear()
endfunction


function! AccordionStart(size)
  let g:accordion_size = a:size
  call Accordion()
endfunction

function! AccordionStartTab(size)
  let t:accordion_size = a:size
  call Accordion()
endfunction

function! s:WindowIsShrunk()
  return &winminwidth == 0
endfunction

function! s:ShrinkWindow()
  setl winminwidth=0
  0 wincmd | 
  setl winfixwidth
endfunction

function! s:UnshrinkWindow()
  setl nowinfixwidth
endfunction

"return x if a window was just deleted
function! g:GetMovementDirection()
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

function! AccordionClear()
  let prev_running = s:accordion_running
  let s:accordion_running=1
  let curwin = winnr()
  windo call s:UnshrinkWindow()
  exe curwin . " wincmd w"
  wincmd =
  let s:accordion_running=prev_running
endfunction

"can be called with no arguments or with the first argument as the size
function! Accordion(...)
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
    let direction = g:GetMovementDirection()
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

function! s:GetDesiredViewport(size, direction)
  let desired_viewport = {}
  let desired_viewport[a:direction] = 0
  let desired_viewport[s:opposites[a:direction]] = a:size - 1
  return desired_viewport
endfunction

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

function! s:SetViewport(desired_viewport)
  "echom "sv0 ".string(winnr())
  "echom "desired:" . string(a:desired_viewport)
  let adjusted_viewport = s:GetAdjustedViewport(a:desired_viewport)
  "echom "adjusted:" . string(adjusted_viewport)
  call AccordionClear()
  for [direction, padding] in items(adjusted_viewport)
    call s:SetViewportInDirection(direction, padding)
  endfor
  wincmd =
endfunction

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

command! -nargs=* Accordion call Accordion(<f-args>)
command! AccordionClear call AccordionClear()
command! -nargs=1 AccordionStart call AccordionStart(<f-args>)
command! -nargs=1 AccordionStartTab call AccordionStartTab(<f-args>)
command! AccordionStop call AccordionStop()

