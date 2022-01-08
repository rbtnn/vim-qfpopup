
let g:loaded_qfpopup = 1

let s:width = 50
let s:height = 3
let s:screenrow = get(s:, 'screenrow', -1)
let s:winid = get(s:, 'winid', -1)
let s:bnr = get(s:, 'bnr', -1)

function! s:qfpopup() abort
	let xs = getqflist()
	if empty(xs) || (&buftype == 'terminal') || get(g:, 'qfpopup_disabled', v:false)
		call s:close()
	else
		let curr_idx = get(getqflist({ 'idx': 0 }), 'idx', 0)
		let st = (-1 == curr_idx)
			\ ? -1
			\ : ((curr_idx < 2)
			\   ? 0
			\   : (len(xs) == curr_idx)
			\     ? len(xs) - s:height
			\     : curr_idx - 1 - 1
			\   )
		let ed = (-1 == curr_idx) ? -1 : (st + s:height - 1)
		let lines = [printf('Quickfix %d/%d', curr_idx, len(xs))]
		for i in range(st, ed)
			if 0 <= i && i < len(xs)
				let x = xs[i]
				let lines += [
					\   printf('%s %s|%d col %d| %s ',
					\     i + 1 == curr_idx ? '>' : ' ',
					\     fnamemodify(bufname(x['bufnr']), ':t'),
					\     x['lnum'], x['col'], x['text'])
					\ ]
			endif
		endfor
		if screenrow() <= &lines - &cmdheight
			let s:screenrow = screenrow()
		endif
		let line = &lines / 3 < s:screenrow ? 2 : &lines - &cmdheight - s:height
		let col = &columns - 1
		if has('tabsidebar')
			if (2 == &showtabsidebar) || ((1 == &showtabsidebar) && (1 < tabpagenr('$')))
				let col -= &tabsidebarcolumns
			endif
		endif

		if tabpagenr() != get(get(getwininfo(s:winid), 0, {}), 'tabnr', -1)
			call s:close()
		endif

		call s:open(lines, line, col)
	endif
endfunction

function! s:open(lines, line, col) abort
	if has('nvim')
		let opts = {
			\ 'relative': 'editor',
			\ 'width': s:width,
			\ 'height': s:height + 1,
			\ 'row': a:line - 1,
			\ 'col': a:col,
			\ 'focusable': 0,
			\ 'style': 'minimal'
			\ }
		if -1 == s:bnr
			let s:bnr = nvim_create_buf(v:false, v:true)
		endif
		if -1 == s:winid
			let s:winid = nvim_open_win(s:bnr, 0, opts)
			call s:win_execute()
		endif
		call nvim_buf_set_lines(s:bnr, 0, -1, v:true, a:lines)
		call nvim_win_set_config(s:winid, opts)
	else
		if -1 == index(popup_list(), s:winid)
			let s:winid = popup_create([], {
				\ 'pos': 'topright',
				\ 'minwidth': s:width,
				\ 'maxwidth': s:width,
				\ })
			call s:win_execute()
		endif

		call popup_settext(s:winid, a:lines)
		call popup_setoptions(s:winid, {
			\ 'line': a:line,
			\ 'col': a:col,
			\ })
	endif
endfunction

function! s:close() abort
	if -1 != s:winid
		if has('nvim')
			silent! call nvim_win_close(s:winid, 0)
		else
			call popup_close(s:winid)
		endif
	endif
	let s:winid = -1
endfunction

function! s:win_execute() abort
	call win_execute(s:winid, 'setfiletype qf')
	call win_execute(s:winid, 'setlocal nowrap')
	call win_execute(s:winid, 'setlocal buftype=nofile')
endfunction

augroup qfpopup
	autocmd!
	autocmd VimResized,BufEnter          * :call <SID>qfpopup()
	autocmd CursorMoved,CursorMovedI     * :call <SID>qfpopup()
	if has('nvim')
		autocmd TermEnter                * :call <SID>qfpopup()
	else
		autocmd TerminalOpen             * :call <SID>qfpopup()
	endif
augroup END

