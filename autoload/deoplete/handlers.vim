"=============================================================================
" FILE: handlers.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

function! deoplete#handlers#_init() abort "{{{
  augroup deoplete
    autocmd InsertLeave * call s:on_insert_leave()
    autocmd CompleteDone * call s:complete_done()
    autocmd InsertCharPre * call s:on_insert_char_pre()

    autocmd TextChangedI * call s:completion_begin("TextChangedI")
    autocmd InsertEnter * call s:completion_begin("InsertEnter")
  augroup END
endfunction"}}}

function! s:completion_begin(event) abort "{{{
  let context = deoplete#init#_context(a:event, [])

  let disable_auto_complete =
        \ deoplete#util#get_simple_buffer_config(
        \   'b:deoplete_disable_auto_complete',
        \   'g:deoplete#disable_auto_complete')

  " Skip
  if &paste
        \ || (a:event !=# 'Manual' && disable_auto_complete)
        \ || (&l:completefunc != '' && &l:buftype =~# 'nofile')
        \ || (context.position ==# get(g:deoplete#_context, 'position', [])
        \      && (get(v:completed_item, 'word', '') == ''
        \         || empty(filter(copy(g:deoplete#delimiters),
        \         'strridx(v:completed_item.word, v:val)
        \          == (len(v:completed_item.word) - len(v:val))'))))
        \ || (a:event ==# 'InsertEnter'
        \     && has_key(g:deoplete#_context, 'position'))
    return
  endif

  " Save the previous position
  let g:deoplete#_context.position = context.position

  " Call omni completion
  for filetype in context.filetypes
    for pattern in deoplete#util#convert2list(
          \ deoplete#util#get_buffer_config(filetype,
          \ 'b:deoplete_omni_patterns',
          \ 'g:deoplete#omni_patterns',
          \ 'g:deoplete#_omni_patterns'))
      if deoplete#util#is_eskk_convertion()
            \ || (pattern != '' && &l:omnifunc != ''
            \ && context.input =~# '\%('.pattern.'\)$')
        call deoplete#mappings#_set_completeopt()
        call feedkeys("\<C-x>\<C-o>", 'n')
        return
      endif
    endfor
  endfor

  call rpcnotify(g:deoplete#_channel_id, 'completion_begin', context)
endfunction"}}}

function! s:on_insert_leave() abort "{{{
  let g:deoplete#_context = {}
endfunction"}}}

function! s:complete_done() abort "{{{
  if get(v:completed_item, 'word', '') != ''
    let word = v:completed_item.word
    if !has_key(g:deoplete#_rank, word)
      let g:deoplete#_rank[word] = 1
    else
      let g:deoplete#_rank[word] += 1
    endif
  endif

  if get(g:deoplete#_context, 'refresh', 0)
    " Don't skip completion
    let g:deoplete#_context.refresh = 0
    return
  endif

  let g:deoplete#_context.position = getpos('.')
endfunction"}}}

function! s:on_insert_char_pre() abort "{{{
  if !pumvisible() || !g:deoplete#enable_refresh_always
    return
  endif

  " Auto refresh
  call feedkeys("\<Plug>(deoplete_auto_refresh)")
endfunction"}}}

" vim: foldmethod=marker
