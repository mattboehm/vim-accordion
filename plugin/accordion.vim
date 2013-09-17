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
"start layout:
command! -nargs=1 Accordion call accordion#StartTab(<f-args>)
command! -nargs=1 AccordionAll call accordion#Start(<f-args>)
command! AccordionDiff call accordion#Diff()
"stop layout:
command! AccordionStop call accordion#Stop()
"change size:
command! AccordionZoomIn call accordion#ChangeSize(-1)
command! AccordionZoomOut call accordion#ChangeSize(1)
"change layout without starting/stopping
command! -nargs=* AccordionOnce call accordion#Accordion(<f-args>)
command! AccordionClear call accordion#Clear()
"}}}
" vim: et sw=2 sts=2 foldmethod=marker foldmarker={{{,}}}
