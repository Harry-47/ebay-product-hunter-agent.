<#
Minimal XLSX writer (Office Open XML) for the daily review workbook. No Excel, Python or extra modules needed.
Dot-source it:  . "$PSScriptRoot\xlsx_writer.ps1"

New-XlsxWorkbook -Path <file.xlsx> -Sheets @( @{ Name='...'; Columns=@(@{ Header='...'; Width=20; Type='text' }, ...); Rows=@( @(v1, v2, ...), ... ) } )

Column Type: text | wrap | int | currency | percent | date | link | auto (numbers stay numbers, text wraps)
Cell values:
  - plain value (string or number). Non-numeric values in numeric columns are written as text (e.g. 'UNKNOWN').
  - @{ Value = <v>; Estimated = $true }  -> highlighted as ESTIMATED (italic, light yellow)
  - link column: @{ Url = 'https://...'; Text = 'Open Source' }. No/blank Url -> cell shows UNKNOWN, no hyperlink.
  - percent: a fraction (0.25 = 25%). date: 'yyyy-MM-dd' string or [datetime].
The file is created with FileMode CreateNew: an existing workbook is never overwritten.
#>
Add-Type -AssemblyName System.IO.Compression

$script:XlsxPound = [string][char]0x00A3

function ConvertTo-XlsxText([string]$s) {
    if ($null -eq $s) { return '' }
    $s = [regex]::Replace($s, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
    return [System.Security.SecurityElement]::Escape($s)
}
function Get-XlsxColName([int]$i) {
    $n = ''; while ($i -gt 0) { $m = ($i - 1) % 26; $n = [char](65 + $m) + $n; $i = [int][math]::Floor(($i - 1) / 26) }; return $n
}
function Test-XlsxNum($v, [ref]$out) {
    if ($v -is [double] -or $v -is [int] -or $v -is [decimal] -or $v -is [long]) { $out.Value = [double]$v; return $true }
    $d = 0.0
    if ($v -is [string] -and [double]::TryParse($v.Trim().TrimStart($script:XlsxPound), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { $out.Value = $d; return $true }
    return $false
}

# Style indexes (cellXfs in styles.xml)
$script:XS = @{ default = 0; header = 1; wrap = 2; currency = 3; percent = 4; date = 5; link = 6; currencyEst = 7; percentEst = 8; textEst = 9; int = 10 }

function Get-XlsxStylesXml {
    $p = $script:XlsxPound
@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="3"><numFmt numFmtId="164" formatCode="&quot;$p&quot;#,##0.00"/><numFmt numFmtId="165" formatCode="0.0%"/><numFmt numFmtId="166" formatCode="dd mmm yyyy"/></numFmts>
<fonts count="4"><font><sz val="11"/><name val="Calibri"/><family val="2"/></font><font><b/><sz val="11"/><name val="Calibri"/><family val="2"/></font><font><u/><sz val="11"/><color rgb="FF0563C1"/><name val="Calibri"/><family val="2"/></font><font><i/><sz val="11"/><name val="Calibri"/><family val="2"/></font></fonts>
<fills count="4"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFD9E1F2"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFF2CC"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="11">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"><alignment vertical="top"/></xf>
<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="top" horizontal="left"/></xf>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="164" fontId="3" fillId="3" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="165" fontId="3" fillId="3" borderId="0" xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="0" fontId="3" fillId="3" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="1" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="top" horizontal="left"/></xf>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>
"@
}

function New-XlsxSheetXml($sheet, [int]$sheetIndex, [System.Collections.Generic.List[string]]$linkTargets) {
    $cols = @($sheet.Columns); $rows = @($sheet.Rows)
    $lastCol = Get-XlsxColName $cols.Count; $lastRow = $rows.Count + 1
    $sb = New-Object System.Text.StringBuilder
    $links = New-Object System.Text.StringBuilder
    [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    [void]$sb.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">')
    [void]$sb.Append("<dimension ref=""A1:$lastCol$lastRow""/>")
    $sel = if ($sheetIndex -eq 1) { ' tabSelected="1"' } else { '' }
    [void]$sb.Append("<sheetViews><sheetView workbookViewId=""0""$sel><pane ySplit=""1"" topLeftCell=""A2"" activePane=""bottomLeft"" state=""frozen""/><selection pane=""bottomLeft"" activeCell=""A2"" sqref=""A2""/></sheetView></sheetViews>")
    [void]$sb.Append('<sheetFormatPr defaultRowHeight="15"/><cols>')
    for ($c = 0; $c -lt $cols.Count; $c++) { $w = if ($cols[$c].Width) { $cols[$c].Width } else { 18 }; [void]$sb.Append("<col min=""$($c+1)"" max=""$($c+1)"" width=""$w"" customWidth=""1""/>") }
    [void]$sb.Append('</cols><sheetData>')
    # header
    [void]$sb.Append('<row r="1">')
    for ($c = 0; $c -lt $cols.Count; $c++) { [void]$sb.Append("<c r=""$(Get-XlsxColName ($c+1))1"" t=""inlineStr"" s=""$($script:XS.header)""><is><t xml:space=""preserve"">$(ConvertTo-XlsxText $cols[$c].Header)</t></is></c>") }
    [void]$sb.Append('</row>')
    $r = 1
    foreach ($row in $rows) {
        $r++; [void]$sb.Append("<row r=""$r"">")
        for ($c = 0; $c -lt $cols.Count; $c++) {
            $ref = "$(Get-XlsxColName ($c+1))$r"; $type = $cols[$c].Type; $cell = $row[$c]
            $est = $false; $val = $cell
            if ($cell -is [hashtable] -and $cell.ContainsKey('Estimated')) { $est = [bool]$cell.Estimated; $val = $cell.Value }
            if ($type -eq 'link') {
                $url = if ($cell -is [hashtable]) { "$($cell.Url)".Trim() } else { '' }
                if ($url -match '^https?://\S+$') {
                    $txt = if ($cell.Text) { $cell.Text } else { 'Open link' }
                    $linkTargets.Add($url); $rid = "rId$($linkTargets.Count)"
                    [void]$sb.Append("<c r=""$ref"" t=""inlineStr"" s=""$($script:XS.link)""><is><t xml:space=""preserve"">$(ConvertTo-XlsxText $txt)</t></is></c>")
                    [void]$links.Append("<hyperlink ref=""$ref"" r:id=""$rid"" tooltip=""$(ConvertTo-XlsxText $url)""/>")
                } else {
                    [void]$sb.Append("<c r=""$ref"" t=""inlineStr"" s=""$($script:XS.default)""><is><t>UNKNOWN</t></is></c>")
                }
                continue
            }
            $num = 0.0; $isNum = $false
            if ($type -in 'int', 'currency', 'percent') { $isNum = Test-XlsxNum $val ([ref]$num) }
            if ($type -eq 'auto' -and ($val -is [int] -or $val -is [long] -or $val -is [double])) { $isNum = $true; $num = [double]$val; $type = 'int' }
            if ($type -eq 'date' -and $val) {
                $dt = [datetime]::MinValue
                if ($val -is [datetime]) { $num = $val.ToOADate(); $isNum = $true }
                elseif ([datetime]::TryParseExact("$val", 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, 'None', [ref]$dt)) { $num = $dt.ToOADate(); $isNum = $true }
            }
            if ($isNum) {
                $s = switch ($type) { 'int' { $script:XS.int } 'currency' { if ($est) { $script:XS.currencyEst } else { $script:XS.currency } } 'percent' { if ($est) { $script:XS.percentEst } else { $script:XS.percent } } 'date' { $script:XS.date } }
                [void]$sb.Append("<c r=""$ref"" s=""$s""><v>$($num.ToString('R', [Globalization.CultureInfo]::InvariantCulture))</v></c>")
            } else {
                $text = if ($null -eq $val -or "$val" -eq '') { '' } else { "$val" }
                if ($text -eq '') { continue }
                $s = if ($est) { $script:XS.textEst } elseif ($type -in 'wrap', 'auto') { $script:XS.wrap } else { $script:XS.default }
                [void]$sb.Append("<c r=""$ref"" t=""inlineStr"" s=""$s""><is><t xml:space=""preserve"">$(ConvertTo-XlsxText $text)</t></is></c>")
            }
        }
        [void]$sb.Append('</row>')
    }
    [void]$sb.Append('</sheetData>')
    if ($sheet.AutoFilter -ne $false) { [void]$sb.Append("<autoFilter ref=""A1:$lastCol$lastRow""/>") }
    if ($links.Length) { [void]$sb.Append("<hyperlinks>$($links.ToString())</hyperlinks>") }
    [void]$sb.Append('<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>')
    return $sb.ToString()
}

function New-XlsxWorkbook {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object[]]$Sheets)
    $enc = New-Object System.Text.UTF8Encoding($false)
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew)   # never overwrite
    try {
        $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
        $put = { param($name, $content) $e = $zip.CreateEntry($name, [System.IO.Compression.CompressionLevel]::Optimal); $w = New-Object System.IO.StreamWriter($e.Open(), $enc); $w.Write($content); $w.Dispose() }
        $ns = 'http://schemas.openxmlformats.org/package/2006/relationships'
        $ctSheets = ''; $wbSheets = ''; $wbRels = ''; $defNames = ''
        for ($i = 1; $i -le $Sheets.Count; $i++) {
            $sh = $Sheets[$i - 1]
            $targets = New-Object System.Collections.Generic.List[string]
            & $put "xl/worksheets/sheet$i.xml" (New-XlsxSheetXml $sh $i $targets)
            if ($targets.Count) {
                $rels = for ($k = 0; $k -lt $targets.Count; $k++) { "<Relationship Id=""rId$($k+1)"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"" Target=""$(ConvertTo-XlsxText $targets[$k])"" TargetMode=""External""/>" }
                & $put "xl/worksheets/_rels/sheet$i.xml.rels" "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><Relationships xmlns=""$ns"">$($rels -join '')</Relationships>"
            }
            $ctSheets += "<Override PartName=""/xl/worksheets/sheet$i.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml""/>"
            $wbSheets += "<sheet name=""$(ConvertTo-XlsxText $sh.Name)"" sheetId=""$i"" r:id=""rId$i""/>"
            $wbRels += "<Relationship Id=""rId$i"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"" Target=""worksheets/sheet$i.xml""/>"
            if ($sh.AutoFilter -ne $false) {
                $lc = Get-XlsxColName @($sh.Columns).Count; $lr = @($sh.Rows).Count + 1
                $defNames += "<definedName name=""_xlnm._FilterDatabase"" localSheetId=""$($i-1)"" hidden=""1"">'$(ConvertTo-XlsxText ($sh.Name -replace "'", "''"))'!`$A`$1:`$$lc`$$lr</definedName>"
            }
        }
        $n = $Sheets.Count
        $wbRels += "<Relationship Id=""rId$($n+1)"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"" Target=""styles.xml""/>"
        & $put '[Content_Types].xml' "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><Types xmlns=""http://schemas.openxmlformats.org/package/2006/content-types""><Default Extension=""rels"" ContentType=""application/vnd.openxmlformats-package.relationships+xml""/><Default Extension=""xml"" ContentType=""application/xml""/><Override PartName=""/xl/workbook.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml""/>$ctSheets<Override PartName=""/xl/styles.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml""/><Override PartName=""/docProps/core.xml"" ContentType=""application/vnd.openxmlformats-package.core-properties+xml""/><Override PartName=""/docProps/app.xml"" ContentType=""application/vnd.openxmlformats-officedocument.extended-properties+xml""/></Types>"
        & $put '_rels/.rels' "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><Relationships xmlns=""$ns""><Relationship Id=""rId1"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"" Target=""xl/workbook.xml""/><Relationship Id=""rId2"" Type=""http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties"" Target=""docProps/core.xml""/><Relationship Id=""rId3"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties"" Target=""docProps/app.xml""/></Relationships>"
        & $put 'xl/workbook.xml' "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><workbook xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main"" xmlns:r=""http://schemas.openxmlformats.org/officeDocument/2006/relationships""><bookViews><workbookView activeTab=""0""/></bookViews><sheets>$wbSheets</sheets>$(if ($defNames) { "<definedNames>$defNames</definedNames>" })</workbook>"
        & $put 'xl/_rels/workbook.xml.rels' "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><Relationships xmlns=""$ns"">$wbRels</Relationships>"
        & $put 'xl/styles.xml' (Get-XlsxStylesXml)
        $now = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        & $put 'docProps/core.xml' "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><cp:coreProperties xmlns:cp=""http://schemas.openxmlformats.org/package/2006/metadata/core-properties"" xmlns:dc=""http://purl.org/dc/elements/1.1/"" xmlns:dcterms=""http://purl.org/dc/terms/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""><dc:title>eBay Product Hunt</dc:title><dc:creator>eBay Product Hunter agent</dc:creator><dcterms:created xsi:type=""dcterms:W3CDTF"">$now</dcterms:created></cp:coreProperties>"
        & $put 'docProps/app.xml' "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?><Properties xmlns=""http://schemas.openxmlformats.org/officeDocument/2006/extended-properties""><Application>Microsoft Excel</Application></Properties>"
        $zip.Dispose()
    } finally { $fs.Dispose() }
}
