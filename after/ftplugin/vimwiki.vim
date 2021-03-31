augroup vimwiki
  " check internet
  if !exists('g:vimwiki_sync_connection')
    let output =  system("ping -q -w1 -c1 github.com")
    if v:shell_error != 0
      echom "No connection"
      let g:vimwiki_sync_connection = 0
      finish
    endif
  else
    finish
  endif

  if !exists('g:zettel_synced')
    let g:zettel_synced = 0
  else
    finish
  endif

  " g:zettel_dir is defined by vim_zettel
  if !exists('g:zettel_dir')
    let g:zettel_dir = vimwiki#vars#get_wikilocal('path') "VimwikiGet('path',g:vimwiki_current_idx)
  endif

  " don't try to start synchronization if the opend file is not in vimwiki
  " path
  let current_dir = expand("%:p:h")
  if !current_dir ==# fnamemodify(g:zettel_dir, ":h")
    finish
  endif

  " don't sync temporary wiki
  if vimwiki#vars#get_wikilocal('is_temporary_wiki') == 1
    finish
  endif

  function! s:git_action(action)
      let gitjob = jobstart("git -C " . g:zettel_dir . " " . a:action, {"on_exit": "My_on_exit_action"})
  endfunction

  " NEOVIM
  function! My_on_exit_action(job_id, exit_code, event_type)
    if a:exit_code != 0
      echom "Sync error!"
    endif
    execute 'checktime'
  endfunction

  function! My_on_exit_pull(job_id, exit_code, event_type)
    if a:exit_code != 0
      echom "Sync error!"
      let g:zettel_synced = 0
    endif
    execute 'checktime'
  endfunction

  " using asynchronous jobs
  " we should add some error handling
  function! s:pull_changes()
    if g:zettel_synced==0
      let g:zettel_synced = 1
      let gitjob = jobstart("git -C " . g:zettel_dir . " pull", {"on_exit": "My_on_exit_pull"})
    endif
  endfunction

  " push changes
  function! s:push_changes()
    let gitjob = jobstart(
          \ "git -C " . g:zettel_dir . " commit -m \"Auto commit + push. `date`\";" .
          \ "git -C " . g:zettel_dir . " push",
          \ {"detach": v:true})
  endfunction

  " sync changes at the start
  au! VimEnter * call <sid>pull_changes()
  au! BufRead * call <sid>pull_changes()

  au! BufWritePost * call <sid>git_action("add .")
  au! BufLeave * call <sid>git_action("add .")
  au! FocusLost * call <sid>git_action("add .")
  au! WinLeave * call <sid>git_action("add .")

  au! VimLeave * call <sid>push_changes()
augroup END
