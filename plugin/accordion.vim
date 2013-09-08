"Header Guard:{{{
if exists('g:loaded_accordion')
  finish
endif
let g:loaded_accordion = 1
"}}}
"Setup Listener:{{{
if !exists("g:accordion_listening")
  let g:accordion_listening = 1
endif
if g:accordion_listening
  augroup accordion
    autocmd!
    autocmd WinEnter * call accordion#Accordion()
  augroup end
else
  augroup accordion
    autocmd!
  augroup end
endif
"}}}
"Commands:{{{
command! -nargs=* Accordion call accordion#Accordion(<f-args>)
command! AccordionClear call accordion#Clear()
command! -nargs=1 AccordionStart call accordion#Start(<f-args>)
command! -nargs=1 AccordionStartTab call accordion#StartTab(<f-args>)
command! AccordionDiff call accordion#Diff()
command! AccordionStop call accordion#Stop()
command! AccordionZoomIn call accordion#ChangeSize(-1)
command! AccordionZoomOut call accordion#ChangeSize(1)
"}}}
" vim: foldmethod=marker foldmarker={{{,}}}
