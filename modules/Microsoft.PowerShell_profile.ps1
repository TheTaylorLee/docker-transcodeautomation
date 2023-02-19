Set-PSReadLineOption -HistorySavePath /docker-transcodeautomation/data/pwsh_history.txt
Set-PSReadLineOption -BellStyle None -EditMode Windows
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete