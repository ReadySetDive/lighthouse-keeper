# Serves the web export on localhost for cloudflared to tunnel to a phone.
$root = "$PSScriptRoot\build\web"
$contentTypes = @{
    ".html" = "text/html"
    ".js"   = "text/javascript"
    ".wasm" = "application/wasm" # browsers refuse to stream-compile wasm without this
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
}

$listener = [Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()
while ($listener.IsListening) {
    $context = $listener.GetContext()
    $path = $context.Request.Url.LocalPath
    if ($path -eq "/") { $path = "/index.html" }
    $file = Join-Path $root $path
    $response = $context.Response
    if (Test-Path $file -PathType Leaf) {
        $response.ContentType = $contentTypes[[IO.Path]::GetExtension($file)]
        # Phones cache aggressively; without this a rebuild looks like nothing changed
        $response.Headers.Add("Cache-Control", "no-store")
        $bytes = [IO.File]::ReadAllBytes($file)
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $response.StatusCode = 404
    }
    $response.Close()
}
