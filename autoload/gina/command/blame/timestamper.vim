let s:DateTime = vital#gina#import('DateTime')


function! gina#command#blame#timestamper#new(...) abort
  let timestamper = deepcopy(s:timestamper)
  let timestamper._now = a:0 == 0 ? s:DateTime.now() : a:1
  let timestamper._cache_timezone = {}
  let timestamper._cache_datetime = {}
  let timestamper._cache_timestamp = {}
  return timestamper
endfunction


" Timestamper ----------------------------------------------------------------
let s:timestamper = {}

function! s:timestamper._timezone(timezone) abort
  if has_key(self._cache_timezone, a:timezone)
    return self._cache_timezone[a:timezone]
  endif
  let timezone = s:DateTime.timezone(a:timezone)
  let self._cache_timezone[a:timezone] = timezone
  return timezone
endfunction

function! s:timestamper._datetime(epoch, timezone) abort
  let cname = a:epoch . a:timezone
  if has_key(self._cache_datetime, cname)
    return self._cache_datetime[cname]
  endif
  let timezone = self._timezone(a:timezone)
  let datetime = s:DateTime.from_unix_time(a:epoch, timezone)
  let self._cache_datetime[cname] = datetime
  return datetime
endfunction

function! s:timestamper.format(epoch, timezone) abort
  let cname = a:epoch . a:timezone
  if has_key(self._cache_timestamp, cname)
    return self._cache_timestamp[cname]
  endif
  let datetime = self._datetime(a:epoch, a:timezone)
  let timedelta = datetime.delta(self._now)
  if timedelta.duration().months() < 3
    let timestamp = timedelta.about()
  elseif datetime.year() == self._now.year()
    let timestamp = datetime.strftime(
          \ g:gina#command#blame#timestamper#format1
          \)
  else
    let timestamp = datetime.strftime(
          \ g:gina#command#blame#timestamper#format2
          \)
  endif
  let self._cache_timestamp[cname] = timestamp
  return timestamp
endfunction


" Config ---------------------------------------------------------------------
call gina#config(expand('<sfile>'), {
      \ 'format1': '%d %b',
      \ 'format2': '%d %b, %Y',
      \})
