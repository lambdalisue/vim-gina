function install_vim($version, $arch) {
  if ($version -eq "latest") {
    $precursor = "http://vim-jp.org/redirects/vim/vim-win32-installer/latest/${arch}/"
    $redirect = Invoke-WebRequest -URI $precursor
    $url = $redirect.Links[0].href
  }
  else {
    $url = "https://github.com/vim/vim-win32-installer/releases/download/v${version}/gvim_${version}_${arch}.zip"
  }
  $zip = "$Env:APPVEYOR_BUILD_FOLDER\\vim.zip"
  Write-Output "URL: $url"
  (New-Object Net.WebClient).DownloadFile($url, $zip)
  [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') > $null
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $Env:APPVEYOR_BUILD_FOLDER)
  $Env:THEMIS_VIM = "$(Get-ChildItem $Env:APPVEYOR_BUILD_FOLDER\\vim\\vim*\\vim.exe | Select -First 1)"
}

function install_neovim($version, $arch) {
  if ($version -eq "latest") {
    $url = "https://github.com/neovim/neovim/releases/download/nightly/nvim-win${arch}.zip"
  }
  else {
    $url = "https://github.com/neovim/neovim/releases/download/v${version}/nvim-win${arch}.zip"
  }
  $zip = "$Env:APPVEYOR_BUILD_FOLDER\\nvim.zip"
  Write-Output "URL: $url"
  (New-Object Net.WebClient).DownloadFile($url, $zip)
  [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') > $null
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $Env:APPVEYOR_BUILD_FOLDER)
  $Env:THEMIS_VIM = "$Env:APPVEYOR_BUILD_FOLDER\\Neovim\\bin\\nvim.exe"
  $Env:THEMIS_ARGS = '-e -s --headless'
}

Write-Output "**********************************************************************"
Write-Output "Vim:     $Env:VIM"
Write-Output "Version: $Env:VIM_VERSION"
Write-Output "Arch:    $Env:VIM_ARCH"
Write-Output "**********************************************************************"
if ($Env:VIM -eq "nvim") {
  install_neovim $Env:VIM_VERSION $Env:VIM_ARCH
}
else {
  install_vim $Env:VIM_VERSION $Env:VIM_ARCH
}
