param(
    [string]$MarkdownPath = (Join-Path $PSScriptRoot '..\docs\Informe_APF2.md'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\docs\Informe_APF2.docx')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$markdownPath = [IO.Path]::GetFullPath($MarkdownPath)
$outputPath = [IO.Path]::GetFullPath($OutputPath)
$rootPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$basePath = Split-Path -Parent $markdownPath
$lines = [IO.File]::ReadAllLines($markdownPath, [Text.Encoding]::UTF8)
$xmlNs = 'http://www.w3.org/XML/1998/namespace'
$wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
$relationships = [Collections.Generic.List[string]]::new()
$contentOverrides = [Collections.Generic.List[string]]::new()
$usedImages = [Collections.Generic.List[object]]::new()
$nextRelationshipId = 1
$nextImageId = 1
$body = [Text.StringBuilder]::new()

function Escape-Xml([string]$Value) {
    return [System.Security.SecurityElement]::Escape($Value)
}

function Add-Relationship([string]$Type, [string]$Target, [bool]$External = $false) {
    $id = "rId$script:nextRelationshipId"
    $script:nextRelationshipId++
    $targetMode = if ($External) { ' TargetMode="External"' } else { '' }
    $script:relationships.Add("<Relationship Id=`"$id`" Type=`"$Type`" Target=`"$Target`"$targetMode/>")
    return $id
}

function New-TextRun([string]$Text, [bool]$Bold = $false, [bool]$Code = $false) {
    $escaped = Escape-Xml $Text
    $properties = ''
    if ($Bold) { $properties += '<w:b/>' }
    if ($Code) { $properties += '<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:color w:val="24415B"/>' }
    if ($properties) { $properties = "<w:rPr>$properties</w:rPr>" }
    return "<w:r>$properties<w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
}

function Convert-InlineMarkdown([string]$Text) {
    $result = [Text.StringBuilder]::new()
    $pattern = '\*\*.+?\*\*|`[^`]+`|\[[^\]]+\]\(https?://[^)]+\)'
    $position = 0
    foreach ($match in [regex]::Matches($Text, $pattern)) {
        if ($match.Index -gt $position) {
            [void]$result.Append((New-TextRun $Text.Substring($position, $match.Index - $position)))
        }
        $token = $match.Value
        if ($token.StartsWith('**')) {
            [void]$result.Append((New-TextRun $token.Substring(2, $token.Length - 4) $true))
        } elseif ($token.StartsWith('`')) {
            [void]$result.Append((New-TextRun $token.Substring(1, $token.Length - 2) $false $true))
        } else {
            $linkMatch = [regex]::Match($token, '^\[([^\]]+)\]\((https?://[^)]+)\)$')
            $id = Add-Relationship 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink' $linkMatch.Groups[2].Value $true
            $run = New-TextRun $linkMatch.Groups[1].Value
            [void]$result.Append("<w:hyperlink r:id=`"$id`">$run</w:hyperlink>")
        }
        $position = $match.Index + $match.Length
    }
    if ($position -lt $Text.Length) {
        [void]$result.Append((New-TextRun $Text.Substring($position)))
    }
    return $result.ToString()
}

function Add-Paragraph([string]$Text, [string]$Style = 'Normal', [string]$ExtraProperties = '') {
    $runs = Convert-InlineMarkdown $Text
    [void]$script:body.Append("<w:p><w:pPr><w:pStyle w:val=`"$Style`"/>$ExtraProperties</w:pPr>$runs</w:p>")
}

function Add-Image([string]$Directive) {
    $parts = $Directive -split '\|', 2
    $relativePath = $parts[0].Substring('[[IMAGE:'.Length)
    $caption = if ($parts.Count -gt 1) { $parts[1].TrimEnd(']') } else { $relativePath }
    $source = [IO.Path]::GetFullPath((Join-Path $basePath ($relativePath -replace '/', '\')))
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Image referenced by report is missing: $source"
    }

    $image = [Drawing.Image]::FromFile($source)
    try {
        $maxWidth = 6.5
        $maxHeight = 6.2
        $scale = [Math]::Min($maxWidth / $image.Width, $maxHeight / $image.Height)
        $width = [Math]::Round($image.Width * $scale * 914400)
        $height = [Math]::Round($image.Height * $scale * 914400)
    } finally {
        $image.Dispose()
    }

    $extension = [IO.Path]::GetExtension($source).TrimStart('.').ToLowerInvariant()
    if ($extension -notin @('png', 'jpg', 'jpeg')) {
        throw "Unsupported report image type: $extension"
    }
    $mediaExtension = if ($extension -eq 'jpeg') { 'jpg' } else { $extension }
    $mediaName = "image$script:nextImageId.$mediaExtension"
    $script:nextImageId++
    $imageId = Add-Relationship 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image' "media/$mediaName"
    $script:usedImages.Add([pscustomobject]@{ Source = $source; Media = $mediaName; Extension = $mediaExtension })
    $contentType = "<Default Extension=`"$mediaExtension`" ContentType=`"image/$mediaExtension`"/>"
    if (-not $script:contentOverrides.Contains($contentType)) {
        $script:contentOverrides.Add($contentType)
    }

    $drawing = @"
<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="120" w:after="100"/></w:pPr><w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="$width" cy="$height"/><wp:docPr id="$script:nextImageId" name="$mediaName"/><wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr><a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:nvPicPr><pic:cNvPr id="$script:nextImageId" name="$mediaName"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="$imageId"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$width" cy="$height"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>
"@
    [void]$script:body.Append($drawing)
    Add-Paragraph $caption 'Caption'
}

function Add-Table([string[]]$TableLines) {
    $rows = [Collections.Generic.List[object]]::new()
    foreach ($line in $TableLines) {
        if ($line -match '^\|[\s:|\-]+\|$') { continue }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        $rows.Add($cells)
    }
    if ($rows.Count -eq 0) { return }

    $columnCount = $rows[0].Count
    if ($columnCount -eq 0) { return }
    $columnWidth = [Math]::Floor(9360 / $columnCount)
    $widths = @()
    for ($i = 0; $i -lt $columnCount; $i++) { $widths += $columnWidth }
    $widths[-1] = 9360 - (($columnCount - 1) * $columnWidth)
    [void]$script:body.Append('<w:tbl><w:tblPr><w:tblW w:w="9360" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders><w:top w:val="single" w:sz="4" w:color="D5DCE2"/><w:left w:val="single" w:sz="4" w:color="D5DCE2"/><w:bottom w:val="single" w:sz="4" w:color="D5DCE2"/><w:right w:val="single" w:sz="4" w:color="D5DCE2"/><w:insideH w:val="single" w:sz="4" w:color="D5DCE2"/><w:insideV w:val="single" w:sz="4" w:color="D5DCE2"/></w:tblBorders><w:tblCellMar><w:top w:w="90" w:type="dxa"/><w:bottom w:w="90" w:type="dxa"/><w:start w:w="100" w:type="dxa"/><w:end w:w="100" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>')
    foreach ($width in $widths) { [void]$script:body.Append("<w:gridCol w:w=`"$width`"/>") }
    [void]$script:body.Append('</w:tblGrid>')
    for ($rowIndex = 0; $rowIndex -lt $rows.Count; $rowIndex++) {
        [void]$script:body.Append('<w:tr>')
        for ($columnIndex = 0; $columnIndex -lt $columnCount; $columnIndex++) {
            $cellText = if ($columnIndex -lt $rows[$rowIndex].Count) { $rows[$rowIndex][$columnIndex] } else { '' }
            $shading = if ($rowIndex -eq 0) { '<w:shd w:fill="F2F4F7"/>' } else { '' }
            $bold = if ($rowIndex -eq 0) { '<w:rPr><w:b/></w:rPr>' } else { '' }
            $runs = Convert-InlineMarkdown $cellText
            if ($rowIndex -eq 0 -and $runs -match '^<w:r>') {
                $runs = $runs -replace '^<w:r>', "<w:r>$bold"
            }
            [void]$script:body.Append("<w:tc><w:tcPr><w:tcW w:w=`"$($widths[$columnIndex])`" w:type=`"dxa`"/>$shading</w:tcPr><w:p><w:pPr><w:spacing w:after=`"40`"/></w:pPr>$runs</w:p></w:tc>")
        }
        [void]$script:body.Append('</w:tr>')
    }
    [void]$script:body.Append('</w:tbl>')
    Add-Paragraph '' 'Normal'
}

function Add-ContentsField {
    [void]$script:body.Append('<w:p><w:pPr><w:pStyle w:val="Normal"/></w:pPr><w:fldSimple w:instr="TOC \o &quot;1-2&quot; \h \z \u"><w:r><w:rPr><w:color w:val="6D747B"/><w:i/></w:rPr><w:t>Abra en Word y actualice el índice para mostrar los números de página.</w:t></w:r></w:fldSimple></w:p>')
}

$index = 0
$inCode = $false
$cover = $false
while ($index -lt $lines.Length) {
    $line = $lines[$index]
    $index++
    if ($line.StartsWith('```')) {
        $inCode = -not $inCode
        continue
    }
    if ($inCode) {
        Add-Paragraph $line 'Code'
        continue
    }
    if (-not $line.Trim()) { continue }
    if ($line -eq '[[PAGE_BREAK]]') {
        [void]$body.Append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
        $cover = $false
        continue
    }
    if ($line -eq '[[TOC]]') {
        Add-ContentsField
        continue
    }
    if ($line.StartsWith('[[IMAGE:')) {
        Add-Image $line
        continue
    }
    if ($line.StartsWith('|')) {
        $tableLines = [Collections.Generic.List[string]]::new()
        $tableLines.Add($line)
        while ($index -lt $lines.Length -and $lines[$index].StartsWith('|')) {
            $tableLines.Add($lines[$index])
            $index++
        }
        Add-Table $tableLines.ToArray()
        continue
    }
    if ($line -eq '## Carátula') {
        $cover = $true
        continue
    }
    if ($line.StartsWith('### ')) {
        Add-Paragraph $line.Substring(4) 'Heading3'
        continue
    }
    if ($line.StartsWith('## ')) {
        Add-Paragraph $line.Substring(3) 'Heading2'
        continue
    }
    if ($line.StartsWith('# ')) {
        Add-Paragraph $line.Substring(2) 'Heading1'
        continue
    }
    if ($line -match '^\s*-\s+') {
        $listText = $line -replace '^\s*-\s+', ''
        if ($cover) {
            Add-Paragraph $listText 'CoverMeta'
        } else {
            Add-Paragraph $listText 'Normal' '<w:numPr><w:ilvl w:val="0"/><w:numId w:val="2"/></w:numPr>'
        }
        continue
    }
    if ($line -match '^\s*\d+\.\s+') {
        $listText = $line -replace '^\s*\d+\.\s+', ''
        Add-Paragraph $listText 'Normal' '<w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr>'
        continue
    }
    if ($cover) {
        Add-Paragraph $line 'CoverMeta'
    } else {
        Add-Paragraph $line 'Normal'
    }
}

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
<w:body>$($body.ToString())
<w:sectPr><w:headerReference w:type="default" r:id="rIdHeader"/><w:footerReference w:type="default" r:id="rIdFooter"/><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="540" w:footer="540" w:gutter="0"/></w:sectPr>
</w:body></w:document>
"@

$imageRelationships = [Collections.Generic.List[string]]::new()
$styleRelationship = Add-Relationship 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles' 'styles.xml'
$numberingRelationship = Add-Relationship 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering' 'numbering.xml'
$headerRelationship = Add-Relationship 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/header' 'header1.xml'
$footerRelationship = Add-Relationship 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer' 'footer1.xml'
$settingsRelationship = Add-Relationship 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings' 'settings.xml'
$documentXml = $documentXml.Replace('r:id="rIdHeader"', "r:id=`"$headerRelationship`"").Replace('r:id="rIdFooter"', "r:id=`"$footerRelationship`"")

$headerXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr><w:r><w:t>SISTEMA DE GESTIÓN Y RESERVAS HOTELERAS  |  APF2</w:t></w:r></w:p></w:hdr>'
$footerXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="right"/></w:pPr><w:r><w:t>Sistema de Gestión y Reservas Hoteleras  ·  </w:t></w:r><w:fldSimple w:instr="PAGE"><w:r><w:t>1</w:t></w:r></w:fldSimple></w:p></w:ftr>'
$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/><w:lang w:val="es-PE"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="center"/><w:keepNext/><w:spacing w:before="0" w:after="320"/></w:pPr><w:rPr><w:b/><w:color w:val="173A57"/><w:sz w:val="50"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="center"/></w:pPr><w:rPr><w:color w:val="5B6670"/><w:sz w:val="28"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="320" w:after="160"/></w:pPr><w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="32"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/></w:pPr><w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="26"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="160" w:after="80"/></w:pPr><w:rPr><w:b/><w:color w:val="1F4D78"/><w:sz w:val="24"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="30"/><w:ind w:left="360"/></w:pPr><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:color w:val="24415B"/><w:sz w:val="17"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Caption"><w:name w:val="Caption"/><w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="center"/><w:spacing w:before="40" w:after="180"/></w:pPr><w:rPr><w:color w:val="6D747B"/><w:sz w:val="18"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="CoverMeta"><w:name w:val="CoverMeta"/><w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="center"/><w:spacing w:after="180"/></w:pPr><w:rPr><w:color w:val="303030"/><w:sz w:val="22"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Header"><w:name w:val="header"/><w:basedOn w:val="Normal"/><w:rPr><w:color w:val="6D747B"/><w:sz w:val="18"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Footer"><w:name w:val="footer"/><w:basedOn w:val="Normal"/><w:rPr><w:color w:val="6D747B"/><w:sz w:val="18"/></w:rPr></w:style>
</w:styles>
'@
$numberingXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:abstractNum w:abstractNumId="0"><w:multiLevelType w:val="singleLevel"/><w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr></w:lvl></w:abstractNum>
<w:abstractNum w:abstractNumId="1"><w:multiLevelType w:val="singleLevel"/><w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="•"/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr></w:lvl></w:abstractNum>
<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num><w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>
</w:numbering>
'@
$settingsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:updateFields w:val="true"/><w:defaultTabStop w:val="720"/><w:compat><w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat></w:settings>'
$rootRelationships = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>
'@
$coreXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Sistema de Gestión y Reservas Hoteleras — APF2</dc:title><dc:creator>Equipo APF2</dc:creator><dc:subject>Desarrollo Web Integrado</dc:subject><dcterms:created xsi:type="dcterms:W3CDTF">2026-10-13T00:00:00Z</dcterms:created></cp:coreProperties>'
$appXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>Microsoft Word</Application></Properties>'
$defaultTypes = [Collections.Generic.List[string]]::new()
$defaultTypes.Add('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
$defaultTypes.Add('<Default Extension="xml" ContentType="application/xml"/>')
foreach ($imageType in $contentOverrides) { $defaultTypes.Add($imageType) }
$contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' + ($defaultTypes -join '') + '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>'
$documentRelationships = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + ($relationships -join '') + '</Relationships>'
$parts = [ordered]@{
    '[Content_Types].xml' = $contentTypes
    '_rels/.rels' = $rootRelationships
    'word/document.xml' = $documentXml
    'word/_rels/document.xml.rels' = $documentRelationships
    'word/styles.xml' = $stylesXml
    'word/numbering.xml' = $numberingXml
    'word/settings.xml' = $settingsXml
    'word/header1.xml' = $headerXml
    'word/footer1.xml' = $footerXml
    'docProps/core.xml' = $coreXml
    'docProps/app.xml' = $appXml
}

$outputDirectory = Split-Path -Parent $outputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    throw "Output directory does not exist: $outputDirectory"
}
$temporaryPath = "$outputPath.building"
if (Test-Path -LiteralPath $temporaryPath) {
    Remove-Item -LiteralPath $temporaryPath -Force
}
$fileStream = $null
$archive = $null
try {
    $fileStream = [IO.File]::Open($temporaryPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $archive = [IO.Compression.ZipArchive]::new($fileStream, [IO.Compression.ZipArchiveMode]::Create, $false)
    $utf8 = [Text.UTF8Encoding]::new($false)
    foreach ($part in $parts.GetEnumerator()) {
        $entry = $archive.CreateEntry($part.Key, [IO.Compression.CompressionLevel]::Optimal)
        $stream = $entry.Open()
        $writer = [IO.StreamWriter]::new($stream, $utf8)
        $writer.Write($part.Value)
        $writer.Dispose()
    }
    foreach ($imageFile in $usedImages) {
        $entry = $archive.CreateEntry("word/media/$($imageFile.Media)", [IO.Compression.CompressionLevel]::Optimal)
        $sourceStream = [IO.File]::OpenRead($imageFile.Source)
        $targetStream = $entry.Open()
        $sourceStream.CopyTo($targetStream)
        $targetStream.Dispose()
        $sourceStream.Dispose()
    }
    $archive.Dispose()
    $archive = $null
    $fileStream.Dispose()
    $fileStream = $null

    $verification = [IO.Compression.ZipFile]::OpenRead($temporaryPath)
    try {
        foreach ($entry in $verification.Entries) {
            if ($entry.FullName.EndsWith('.xml') -or $entry.FullName.EndsWith('.rels')) {
                $stream = $entry.Open()
                $reader = [Xml.XmlReader]::Create($stream)
                while ($reader.Read()) { }
                $reader.Dispose()
                $stream.Dispose()
            }
        }
        $documentEntry = $verification.GetEntry('word/document.xml')
        if (-not $documentEntry) { throw 'The Word document part is missing.' }
        $stream = $documentEntry.Open()
        $document = [Xml.XmlDocument]::new()
        $document.Load($stream)
        $stream.Dispose()
        $namespaces = [Xml.XmlNamespaceManager]::new($document.NameTable)
        $namespaces.AddNamespace('w', $wNs)
        $text = ($document.SelectNodes('//w:t', $namespaces) | ForEach-Object { $_.InnerText }) -join ' '
        foreach ($requiredText in @('45154878', '45784512', '16261548', 'Reservas recuperadas desde MySQL con DNI')) {
            if (-not $text.Contains($requiredText)) { throw "Document validation failed; missing text: $requiredText" }
        }
        if ($document.SelectNodes('//w:drawing', $namespaces).Count -lt 5) {
            throw 'The document is missing one or more evidence images.'
        }
    } finally {
        $verification.Dispose()
    }
    Move-Item -LiteralPath $temporaryPath -Destination $outputPath -Force
} catch {
    if ($archive) { $archive.Dispose() }
    if ($fileStream) { $fileStream.Dispose() }
    if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Force }
    throw
}

Write-Output "Created and verified: $outputPath"
