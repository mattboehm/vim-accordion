"nnoremap <F9> :call AccordionStart()<left>
"nnoremap <silent> <F8> :call AccordionStop()<CR>

let s:accordion_running=0

function! AccordionStop()
	augroup multi
		autocmd!
	augroup end
	"unlock window widths
	"TODO only unlocks for this tab, but mapping applies to all tabs
	call s:UnshrinkAllWindows()
endfunction

function! AccordionStart(size)
	augroup multi
		autocmd!
		exe "autocmd WinEnter * call <SID>Accordion(".a:size.")"
	augroup end
	exe "call <SID>Accordion(".a:size.")"
endfunction

function! s:ShrinkWindow()
	setl winminwidth=0
	0 wincmd | 
	setl winfixwidth
endfunction

function! s:UnshrinkWindow()
	setl nowinfixwidth
endfunction

function! s:UnshrinkAllWindows()
	let curwin = winnr()
	windo call s:UnshrinkWindow()
	exe curwin . " wincmd w"
	wincmd =
endfunction

function! s:Accordion(size)
	"accordion can be triggered on the change of window focus
	"this is a hack so accordion doesn't recursively trigger itself
	if !s:accordion_running
		let s:accordion_running=1
		let leftPadding = ceil((a:size - 1)/2.0)
		let rightPadding = floor((a:size - 1)/2.0)
		call s:SetVisibleColumns(leftPadding, rightPadding)
		let s:accordion_running=0
	endif
endfunction

"direction should be h or l for left/right
function! s:ShrinkColumnsInDirection(padding, direction)
	let curwin = winnr()
	"go over `padding` times in the direction
	exe printf("%0.0f", a:padding) . "wincmd " . a:direction
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
	call s:UnshrinkAllWindows()
	call s:ShrinkColumnsInDirection(a:leftPadding, "h")
	call s:ShrinkColumnsInDirection(a:rightPadding, "l")
	wincmd =
endfunction
