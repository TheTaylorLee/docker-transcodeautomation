##Import Functions
$FunctionPathPublic = $PSScriptRoot + "\Public\"

try {
    $PublicFunctions = Get-ChildItem $FunctionPathPublic | ForEach-Object {
        [System.IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) + [Environment]::NewLine
    }

    . ([scriptblock]::Create($PublicFunctions))
}

catch {
    $FunctionListPublic = Get-ChildItem $FunctionPathPublic -Name

    ForEach ($Function in $FunctionListPublic) {
        . ($FunctionPathPublic + $Function)
    }
}