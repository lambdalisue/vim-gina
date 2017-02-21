function install_vim($name)
{
  $ver = $name -replace "^Official\s*", ""
  if ($ver -eq "latest")
  {
    $url1 = 'ftp://ftp.vim.org/pub/vim/pc/vim80w32.zip'
  }
  else
  {
    $url1 = 'ftp://ftp.vim.org/pub/vim/pc/vim80-' + $ver + 'w32.zip'
  }
  $url2 = 'ftp://ftp.vim.org/pub/vim/pc/vim80rt.zip'
  $zip1 = $Env:APPVEYOR_BUILD_FOLDER + '\vim.zip'
  $zip2 = $Env:APPVEYOR_BUILD_FOLDER + '\vim-rt.zip'
  (New-Object Net.WebClient).DownloadFile($url1, $zip1)
  (New-Object Net.WebClient).DownloadFile($url2, $zip2)
  [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') > $null
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zip1, $Env:APPVEYOR_BUILD_FOLDER)
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zip2, $Env:APPVEYOR_BUILD_FOLDER)
  $vim  = $Env:APPVEYOR_BUILD_FOLDER + '\vim\vim80\vim.exe'
  $Env:THEMIS_VIM = $vim
}

function install_kaoriya_vim($url)
{
  $zip = $Env:APPVEYOR_BUILD_FOLDER + '\kaoriya-vim.zip'
  $out = $Env:APPVEYOR_BUILD_FOLDER + '\kaoriya-vim\'
  if ($url.StartsWith('http://vim-jp.org/redirects/')) 
  {
    $redirect = Invoke-WebRequest -URI $url
    (New-Object Net.WebClient).DownloadFile($redirect.Links[0].href, $zip)
  }
  else
  {
    (New-Object Net.WebClient).DownloadFile($url, $zip)
  }
  [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') > $null
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $out)
  $Env:THEMIS_VIM = $out + (Get-ChildItem $out).Name + '\vim.exe'
}

if ($Env:CONDITION.StartsWith("Official"))
{
  install_vim $Env:CONDITION
}
else
{
  install_kaoriya_vim $Env:CONDITION
}
