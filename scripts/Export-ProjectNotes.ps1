param(
    [string]$SourcePath = (Join-Path $PSScriptRoot '../PROJECT_NOTES.md'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '../PROJECT_NOTES.docx')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Escape-Xml([string]$Value) {
    return [System.Security.SecurityElement]::Escape($Value)
}

function Convert-Inline([string]$Value) {
    $Value = [regex]::Replace($Value, '\[([^\]]+)\]\(([^)]+)\)', {
        param($match)
        if ($match.Groups[2].Value.StartsWith('#')) { return $match.Groups[1].Value }
        return $match.Groups[1].Value + ' (' + $match.Groups[2].Value + ')'
    })
    $Value = $Value.Replace('**', '').Replace('`', '')
    return Escape-Xml $Value
}

function New-Paragraph([string]$Text, [string]$Style = 'Normal', [bool]$Literal = $false) {
    $escaped = if ($Literal) { Escape-Xml $Text } else { Convert-Inline $Text }
    return '<w:p><w:pPr><w:pStyle w:val="' + $Style + '"/></w:pPr><w:r><w:t xml:space="preserve">' + $escaped + '</w:t></w:r></w:p>'
}

$body = [System.Text.StringBuilder]::new()
$lines = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $SourcePath).Path, [System.Text.Encoding]::UTF8)
$inCode = $false
$inTable = $false
$codeLanguage = ''
$diagramNumber = 0
foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ($trimmed.StartsWith('```')) {
        if ($inCode) {
            $inCode = $false
        } else {
            $inCode = $true
            $codeLanguage = $trimmed.Substring(3)
            if ($codeLanguage -eq 'mermaid') {
                $diagramNumber++
                if ($diagramNumber -eq 1) {
                    [void]$body.Append((New-Paragraph 'HTTP client -> EmployeeController -> EmployeeServiceImpl' 'Code' $true))
                    [void]$body.Append((New-Paragraph '  -> EmployeeRepository proxy -> JPA / Hibernate' 'Code' $true))
                    [void]$body.Append((New-Paragraph '  -> JDBC driver -> PostgreSQL employee_db' 'Code' $true))
                } else {
                    [void]$body.Append((New-Paragraph 'Client --POST / PUT--> Command service --> Write database' 'Code' $true))
                    [void]$body.Append((New-Paragraph 'Command service --future events--> Projection handler --> Read model' 'Code' $true))
                    [void]$body.Append((New-Paragraph 'Client --future GET--> Query service --> Read model' 'Code' $true))
                }
            }
        }
        continue
    }
    if ($inCode) {
        if ($codeLanguage -ne 'mermaid') { [void]$body.Append((New-Paragraph $line 'Code' $true)) }
        continue
    }
    if ($trimmed.StartsWith('|')) {
        if ($trimmed -match '^\|[\s:|\-]+\|$') { continue }
        $header = -not $inTable
        if ($header) {
            [void]$body.Append('<w:tbl><w:tblPr><w:tblStyle w:val="NotesTable"/><w:tblW w:w="0" w:type="auto"/></w:tblPr>')
            $inTable = $true
        }
        [void]$body.Append('<w:tr>')
        if ($header) { [void]$body.Append('<w:trPr><w:tblHeader/></w:trPr>') }
        foreach ($cell in $trimmed.Trim('|').Split('|')) {
            [void]$body.Append('<w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/></w:tcPr>')
            $style = if ($header) { 'TableHeader' } else { 'TableText' }
            [void]$body.Append((New-Paragraph $cell.Trim() $style))
            [void]$body.Append('</w:tc>')
        }
        [void]$body.Append('</w:tr>')
        continue
    }
    if ($inTable) { [void]$body.Append('</w:tbl>'); $inTable = $false }
    if (-not $trimmed) { continue }
    if ($trimmed -match '^(#{1,6})\s+(.+)$') {
        $level = $Matches[1].Length
        $style = if ($level -eq 1) { 'Title' } else { 'Heading' + ($level - 1) }
        [void]$body.Append((New-Paragraph $Matches[2] $style))
    } elseif ($trimmed -match '^- (.+)$') {
        [void]$body.Append((New-Paragraph ('- ' + $Matches[1]) 'ListText'))
    } elseif ($trimmed -match '^\d+\. ') {
        [void]$body.Append((New-Paragraph $trimmed 'ListText'))
    } else {
        [void]$body.Append((New-Paragraph $trimmed))
    }
}
if ($inTable) { [void]$body.Append('</w:tbl>') }

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="120"/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="300"/></w:pPr><w:rPr><w:b/><w:color w:val="17365D"/><w:sz w:val="40"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="280" w:after="140"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:color w:val="17365D"/><w:sz w:val="30"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="220"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:color w:val="245A81"/><w:sz w:val="25"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="0"/><w:shd w:fill="F2F4F7"/></w:pPr><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="17"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="ListText"><w:name w:val="List Text"/><w:basedOn w:val="Normal"/><w:pPr><w:ind w:left="240"/></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="TableText"><w:name w:val="Table Text"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="70"/></w:pPr><w:rPr><w:sz w:val="19"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="TableHeader"><w:name w:val="Table Header"/><w:basedOn w:val="TableText"/><w:rPr><w:b/><w:color w:val="17365D"/></w:rPr></w:style>
<w:style w:type="table" w:styleId="NotesTable"><w:name w:val="Notes Table"/><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="4" w:color="CDD5DF"/><w:left w:val="single" w:sz="4" w:color="CDD5DF"/><w:bottom w:val="single" w:sz="4" w:color="CDD5DF"/><w:right w:val="single" w:sz="4" w:color="CDD5DF"/><w:insideH w:val="single" w:sz="4" w:color="CDD5DF"/><w:insideV w:val="single" w:sz="4" w:color="CDD5DF"/></w:tblBorders><w:tblCellMar><w:top w:w="80" w:type="dxa"/><w:left w:w="90" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/><w:right w:w="90" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>
</w:styles>
'@
$parts = @{
    '[Content_Types].xml' = '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>'
    '_rels/.rels' = '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'
    'word/_rels/document.xml.rels' = '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>'
    'word/styles.xml' = $styles
    'word/document.xml' = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + $body.ToString() + '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1080" w:right="900" w:bottom="1080" w:left="900"/></w:sectPr></w:body></w:document>'
}

# Parse every XML part before creating the package.
foreach ($value in $parts.Values) { [void]([xml]$value) }
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
$stream = [System.IO.File]::Open($outputFullPath, [System.IO.FileMode]::Create)
$archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($name in $parts.Keys) {
        $entry = $archive.CreateEntry($name)
        $writer = [System.IO.StreamWriter]::new($entry.Open(), [System.Text.UTF8Encoding]::new($false))
        try { $writer.Write($parts[$name]) } finally { $writer.Dispose() }
    }
} finally {
    $archive.Dispose()
    $stream.Dispose()
}
Write-Output "Created $outputFullPath"
