"nnoremap <F9> :call AccordionStart()<left>
"nnoremap <silent> <F8> :call AccordionStop()<CR>

let s:accordion_running=0

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

function! s:ShrinkWindow()
  setl winminwidth=0
  0 wincmd | 
  setl winfixwidth
endfunction

function! s:UnshrinkWindow()
  setl nowinfixwidth
endfunction

function! AccordionClear()
  let curwin = winnr()
  windo call s:UnshrinkWindow()
  exe curwin . " wincmd w"
  wincmd =
endfunction

"can be called with no arguments or with the first argument as the size
function! Accordion(...)
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
    let leftPadding = ceil((size - 1)/2.0)
    let rightPadding = floor((size - 1)/2.0)
    call s:SetVisibleColumns(leftPadding, rightPadding)
    let s:accordion_running=0
  endif
endfunction

"direction should be h or l for left/right
function! s:ShrinkColumnsInDirection(padding, direction)
  let curwin = winnr()
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

function! s:SetVisibleColumns(leftPadding, rightPadding)
  call AccordionClear()
  call s:ShrinkColumnsInDirection(a:leftPadding, "h")
  call s:ShrinkColumnsInDirection(a:rightPadding, "l")
  wincmd =
endfunction

command! -nargs=* Accordion call Accordion(<f-args>)
command! AccordionClear call AccordionClear()
command! -nargs=1 AccordionStart call AccordionStart(<f-args>)
command! -nargs=1 AccordionStartTab call AccordionStartTab(<f-args>)
command! AccordionStop call AccordionStop()

