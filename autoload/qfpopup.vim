
function! qfpopup#exec() abort
	call s:init()
	if get(g:, 'qfpopup_disabled', v:false)
		call s:close()
	elseif &buftype == 'terminal'
		call s:close()
	elseif empty(getqflist())
		call s:close()
	elseif s:displayed_qf()
		call s:close()
	else
		if !s:is_current_qfpopup()
			call s:close()
		endif
		let lines = s:make_lines()
		let [line, col] = s:calc_line_and_col()
		call s:open(lines, line, col)
	endif
endfunction



function! s:init() abort
	let s:TOP = 0
	let s:BOT = 1

	let s:width = get(g:, 'qfpopup_width', 50)
	if s:width < 1
		let s:width = 50
	endif
	let s:height = get(g:, 'qfpopup_height', 4)
	if s:height < 2
		let s:height = 4
	endif
	let s:winid = get(s:, 'winid', -1)
	let s:bnr = get(s:, 'bnr', -1)
	let s:position = get(s:, 'position', s:TOP)
endfunction

function! s:make_lines() abort
	let xs = getqflist()
	let curr_idx = get(getqflist({ 'idx': 0 }), 'idx', 0)
	let st = (-1 == curr_idx)
		\ ? -1
		\ : ((curr_idx <= s:height / 2)
		\   ? 0
		\   : (len(xs) - s:height / 2 < curr_idx)
		\     ? len(xs) - s:height + 1
		\     : curr_idx - s:height / 2
		\   )
	let ed = (-1 == curr_idx) ? -1 : (st + s:height - 2)
	let lines = [printf('Quickfix %d/%d', curr_idx, len(xs))]
	for i in range(st, ed)
		if 0 <= i && i < len(xs)
			let x = xs[i]
			let lnum_and_col = x['lnum']
			if 0 < get(x, 'end_lnum', 0)
				let lnum_and_col = lnum_and_col .. '-' .. x['end_lnum']
			endif
			if 0 < x['col']
				let lnum_and_col = lnum_and_col .. ' ' .. (x['vcol'] ? 'vcol' : 'col') .. ' ' .. x['col']
				if 0 < get(x, 'end_col', 0)
					let lnum_and_col = lnum_and_col .. '-' .. x['end_col']
				endif
			endif
			let lines += [
				\   printf('%s %s|%s| %s ',
				\     i + 1 == curr_idx ? '>' : ' ',
				\     fnamemodify(bufname(x['bufnr']), ':t'),
				\     lnum_and_col, trim(x['text']))
				\ ]
		endif
	endfor
	return lines
endfunction

function! s:calc_line_and_col() abort
	let row = screenrow()
	if &lines - &cmdheight < row
		let row = &lines - &cmdheight
	endif

	if row < &lines / 3
		let s:position = s:BOT
	elseif &lines / 3 * 2 < row
		let s:position = s:TOP
	else
		" use the previous position.
	endif

	if s:position == s:TOP
		let line = 2
		if (2 == &showtabline) || ((1 == &showtabline) && (1 < tabpagenr('$')))
			let line += 1
		endif
	else
		let line = &lines - &cmdheight - s:height
	endif

	let col = &columns - s:width - 1
	if has('tabsidebar')
		if (2 == &showtabsidebar) || ((1 == &showtabsidebar) && (1 < tabpagenr('$')))
			let col -= &tabsidebarcolumns
		endif
	endif

	return [line, col]
endfunction

function! s:open(lines, line, col) abort
	if has('nvim')
		let opts = {
			\ 'relative': 'editor',
			\ 'width': s:width,
			\ 'height': s:height,
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
		endif
		call nvim_buf_set_lines(s:bnr, 0, -1, v:true, a:lines)
		call nvim_win_set_config(s:winid, opts)
	else
		if -1 == index(popup_list(), s:winid)
			let s:winid = popup_create([], {
				\ 'pos': 'topleft',
				\ 'minwidth': s:width,
				\ 'maxwidth': s:width,
				\ })
		endif

		call popup_settext(s:winid, a:lines)
		call popup_setoptions(s:winid, {
			\ 'line': a:line,
			\ 'col': a:col,
			\ })
	endif
	if -1 != s:winid
		call win_execute(s:winid, 'setlocal nowrap')
		call win_execute(s:winid, 'setlocal buftype=nofile')
		call win_execute(s:winid, 'setfiletype qf')
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

function! s:is_current_qfpopup() abort
	return tabpagenr() == get(get(getwininfo(s:winid), 0, {}), 'tabnr', -1)
endfunction

function! s:displayed_qf() abort
	for x in getwininfo()
		if (x['tabnr'] == tabpagenr()) && (getbufvar(x['bufnr'], '&buftype', '') == 'quickfix')
			return v:true
		endif
	endfor
	return v:false
endfunction

