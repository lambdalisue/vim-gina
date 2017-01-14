if has('nvim')
  function! s:start(args, ...) abort
    " Build options for jobstart
    let options = get(a:000, 0, {})
    let job = extend(copy(options), s:job)
    if has_key(options, 'on_exit')
      let job._on_exit = options.on_exit
    endif
    " Start job and return a job instance
    let job._job = jobstart(a:args, job)
    let job._status = job._job > 0 ? 'run' : 'fail'
    let job.args = a:args
    return job
  endfunction


  " Instance -------------------------------------------------------------------
  let s:job = { '_status': 'fail' }

  function! s:job.status() abort
    return self._status
  endfunction

  function! s:job.send(data) abort
    return jobsend(self._job, a:data)
  endfunction

  function! s:job.wait(...) abort
    let timeout = get(a:000, 0, v:null)
    if timeout is v:null
      return jobwait([self._job])[0]
    else
      return jobwait([self._job], timeout)[0]
    endif
  endfunction

  function! s:job.stop() abort
    return jobstop(self._job)
  endfunction

  function! s:job.on_exit(jobid, msg, event) abort
    " Update job status
    let self._status = 'dead'
    " Call user specified callback if exists
    if has_key(self, '_on_exit')
      call call(self._on_exit, [a:jobid, a:msg, a:event], self)
    endif
  endfunction
else
  function! s:start(args, ...) abort
    let job = extend(copy(s:job), get(a:000, 0, {}))
    let job_options = {
          \ 'mode': 'raw',
          \ 'timeout': 10000,
          \}
    if has_key(job, 'on_stdout')
      let job_options.out_cb = function('s:_job_callback', ['stdout', job])
    endif
    if has_key(job, 'on_stderr')
      let job_options.err_cb = function('s:_job_callback', ['stderr', job])
    endif
    if has_key(job, 'on_exit')
      let job_options.exit_cb = function('s:_job_callback', ['exit', job])
    endif
    let job._job = job_start(a:args, job_options)
    let job.args = a:args
    return job
  endfunction

  function! s:_job_callback(event, options, channel, ...) abort
    let raw = get(a:000, 0, '')
    let msg = type(raw) == v:t_string ? split(raw, '\n', 1) : raw
    call call(
          \ a:options['on_' . a:event],
          \ [a:channel, msg, a:event],
          \ a:options
          \)
  endfunction

  function! s:_read_stdout(job) abort
    return split(ch_read(a:job), '\n', 1)
  endfunction

  function! s:_read_stderr(job) abort
    return split(ch_read(a:job, {'part': 'err'}), '\n', 1)
  endfunction


  " Instance -------------------------------------------------------------------
  let s:job = {}

  function! s:job.status() abort
    return job_status(self._job)
  endfunction

  function! s:job.send(data) abort
    let channel = job_getchannel(self._job)
    return ch_sendexpr(channel, a:data)
  endfunction

  function! s:job.stop() abort
    return job_stop(self._job)
  endfunction

  function! s:job.wait(...) abort
    let timeout = get(a:000, 0, v:null)
    let start_time = reltime()
    while timeout is v:null || start_time + timeout > reltime()
      let status = self.status()
      if status ==# 'run'
        let stdout = ch_read(self._job)
        let stderr = ch_read(self._job, {'part': 'err'})
        if has_key(self, 'on_stdout') && !empty(stdout)
          call s:_job_callback('stdout', self, self._job, stdout)
        endif
        if has_key(self, 'on_stderr') && !empty(stderr)
          call s:_job_callback('stderr', self, self._job, stderr)
        endif
      elseif status ==# 'dead'
        let info = job_info(self._job)
        return info.exitval
      else
        return -3
      endif
    endwhile
    return -1
  endfunction
endif
