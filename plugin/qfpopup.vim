
let g:loaded_qfpopup = 1

augroup qfpopup
	autocmd!
	autocmd VimResized,BufEnter          * :call qfpopup#exec()
	autocmd CursorMoved,CursorMovedI     * :call qfpopup#exec()
	if has('nvim')
		autocmd TermEnter                * :call qfpopup#exec()
	else
		autocmd TerminalOpen             * :call qfpopup#exec()
	endif
augroup END
