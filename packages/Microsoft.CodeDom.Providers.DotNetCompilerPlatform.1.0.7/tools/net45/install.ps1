# Copyright (c) .NET Foundation. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param($installPath, $toolsPath, $package, $project)

$compilerPackageName = 'Microsoft.Net.Compilers'
$roslynSubFolder = 'roslyn'

if ($project -eq $null) {
    $project = Get-Project
}

$libDirectory = Join-Path $installPath 'lib\net45'
$projectRoot = $project.Properties.Item('FullPath').Value
$binDirectory = Join-Path $projectRoot 'bin'

# We need to copy the provider assembly into the bin\ folder, otherwise
# Microsoft.VisualStudio.Web.Host.exe cannot find the assembly.
# However, users will see the error after they clean solutions.
New-Item $binDirectory -type directory -force | Out-Null
Copy-Item $libDirectory\* $binDirectory -force | Out-Null

# For Web Site, we need to copy the Roslyn toolset into
# the applicaiton's bin folder. 
# For Web Applicaiton project, this is done in csproj.
if ($project.Type -eq 'Web Site') {
    $packageDirectory = Split-Path $installPath

    # Get the installed Microsoft.Net.Compilers package.
    $compilerPackage = Get-Package -ProjectName $project.Name | Where-Object {$_.Id -eq $compilerPackageName}
    if ($compilerPackage -eq $null)
    {
        Write-Host "Package $compilerPackageName is not installed correctly."
        Write-Host 'The install.ps1 did not complete.'
        break
    }

    if($compilerPackage.Versions -eq $null)
    {
        $compilerVersion = $compilerPackage.Version
    }
    else
    {
		$compilerVersion = @($compilerPackage.Versions)[0]
    }

    $compilerPackageFolderName = $compilerPackage.Id + "." + $compilerVersion
    $compilerPackageDirectory = Join-Path $packageDirectory $compilerPackageFolderName
    if ((Get-Item $compilerPackageDirectory) -isnot [System.IO.DirectoryInfo])
    {
        Write-Host "The install.ps1 cannot find the installation location of package $compilerPackageName, or the pakcage is not installed correctly."
        Write-Host 'The install.ps1 did not complete.'
        break
    }

    $compilerPackageToolsDirectory = Join-Path $compilerPackageDirectory 'tools'
    $roslynSubDirectory = Join-Path $binDirectory $roslynSubFolder
    New-Item $roslynSubDirectory -type directory -force | Out-Null
    Copy-Item $compilerPackageToolsDirectory\* $roslynSubDirectory -force | Out-Null

    # Generate a .refresh file for each dll/exe file.
    Push-Location
    Set-Location $projectRoot
    $relativeAssemblySource = Resolve-Path -relative $compilerPackageToolsDirectory
    Pop-Location

    Get-ChildItem -Path $roslynSubDirectory | `
    Foreach-Object {
        if  (($_.Extension -eq ".dll") -or ($_.Extension -eq ".exe")) {
            $refreshFile = $_.FullName
            $refreshFile += ".refresh"
            $refreshContent = Join-Path $relativeAssemblySource $_.Name    
            Set-Content $refreshFile $refreshContent
        }
    }
}
# SIG # Begin signature block
# MIIkCAYJKoZIhvcNAQcCoIIj+TCCI/UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAf2MwHY6B6NpA8
# BGxEha31/ErMnwdzPRjp4gsxT9P5T6CCDZMwggYRMIID+aADAgECAhMzAAAAjoeR
# pFcaX8o+AAAAAACOMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTYxMTE3MjIwOTIxWhcNMTgwMjE3MjIwOTIxWjCBgzEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9Q
# UjEeMBwGA1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEA0IfUQit+ndnGetSiw+MVktJTnZUXyVI2+lS/qxCv
# 6cnnzCZTw8Jzv23WAOUA3OlqZzQw9hYXtAGllXyLuaQs5os7efYjDHmP81LfQAEc
# wsYDnetZz3Pp2HE5m/DOJVkt0slbCu9+1jIOXXQSBOyeBFOmawJn+E1Zi3fgKyHg
# 78CkRRLPA3sDxjnD1CLcVVx3Qv+csuVVZ2i6LXZqf2ZTR9VHCsw43o17lxl9gtAm
# +KWO5aHwXmQQ5PnrJ8by4AjQDfJnwNjyL/uJ2hX5rg8+AJcH0Qs+cNR3q3J4QZgH
# uBfMorFf7L3zUGej15Tw0otVj1OmlZPmsmbPyTdo5GPHzwIDAQABo4IBgDCCAXww
# HwYDVR0lBBgwFgYKKwYBBAGCN0wIAQYIKwYBBQUHAwMwHQYDVR0OBBYEFKvI1u2y
# FdKqjvHM7Ww490VK0Iq7MFIGA1UdEQRLMEmkRzBFMQ0wCwYDVQQLEwRNT1BSMTQw
# MgYDVQQFEysyMzAwMTIrYjA1MGM2ZTctNzY0MS00NDFmLWJjNGEtNDM0ODFlNDE1
# ZDA4MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0Nv
# ZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsG
# AQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01p
# Y0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkq
# hkiG9w0BAQsFAAOCAgEARIkCrGlT88S2u9SMYFPnymyoSWlmvqWaQZk62J3SVwJR
# avq/m5bbpiZ9CVbo3O0ldXqlR1KoHksWU/PuD5rDBJUpwYKEpFYx/KCKkZW1v1rO
# qQEfZEah5srx13R7v5IIUV58MwJeUTub5dguXwJMCZwaQ9px7eTZ56LadCwXreUM
# tRj1VAnUvhxzzSB7pPrI29jbOq76kMWjvZVlrkYtVylY1pLwbNpj8Y8zon44dl7d
# 8zXtrJo7YoHQThl8SHywC484zC281TllqZXBA+KSybmr0lcKqtxSCy5WJ6PimJdX
# jrypWW4kko6C4glzgtk1g8yff9EEjoi44pqDWLDUmuYx+pRHjn2m4k5589jTajMW
# UHDxQruYCen/zJVVWwi/klKoCMTx6PH/QNf5mjad/bqQhdJVPlCtRh/vJQy4njpI
# BGPveJiiXQMNAtjcIKvmVrXe7xZmw9dVgh5PgnjJnlQaEGC3F6tAE5GusBnBmjOd
# 7jJyzWXMT0aYLQ9RYB58+/7b6Ad5B/ehMzj+CZrbj3u2Or2FhrjMvH0BMLd7Hald
# G73MTRf3bkcz1UDfasouUbi1uc/DBNM75ePpEIzrp7repC4zaikvFErqHsEiODUF
# he/CBAANa8HYlhRIFa9+UrC4YMRStUqCt4UqAEkqJoMnWkHevdVmSbwLnHhwCbww
# ggd6MIIFYqADAgECAgphDpDSAAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5
# MDlaFw0yNjA3MDgyMTA5MDlaMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIw
# MTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQ
# TTS68rZYIZ9CGypr6VpQqrgGOBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULT
# iQ15ZId+lGAkbK+eSZzpaF7S35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYS
# L+erCFDPs0S3XdjELgN1q2jzy23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494H
# DdVceaVJKecNvqATd76UPe/74ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZ
# PrGMXeiJT4Qa8qEvWeSQOy2uM1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5
# bmR/U7qcD60ZI4TL9LoDho33X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGS
# rhwjp6lm7GEfauEoSZ1fiOIlXdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADh
# vKwCgl/bwBWzvRvUVUvnOaEP6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON
# 7E1JMKerjt/sW5+v/N2wZuLBl4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xc
# v3coKPHtbcMojyyPQDdPweGFRInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqw
# iBfenk70lrC8RqBsmNLg1oiMCwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFEhuZOVQBdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQM
# HgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
# IwQYMBaAFHItOgIxkEO5FAVO4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0
# dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUF
# BzAChkJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
# ckF1dDIwMTFfMjAxMV8wM18yMi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGC
# Ny4DMIGDMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2RvY3MvcHJpbWFyeWNwcy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcA
# YQBsAF8AcABvAGwAaQBjAHkAXwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZI
# hvcNAQELBQADggIBAGfyhqWY4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4s
# PvjDctFtg/6+P+gKyju/R6mj82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKL
# UtCw/WvjPgcuKZvmPRul1LUdd5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7
# pKkFDJvtaPpoLpWgKj8qa1hJYx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft
# 0N3zDq+ZKJeYTQ49C/IIidYfwzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4
# MnEnGn+x9Cf43iw6IGmYslmJaG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxv
# FX1Fp3blQCplo8NdUmKGwx1jNpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG
# 0QaxdR8UvmFhtfDcxhsEvt9Bxw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf
# 0AApxbGbpT9Fdx41xtKiop96eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkY
# S//WsyNodeav+vyL6wuA6mk7r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrv
# QQqxP/uozKRdwaGIm1dxVk5IRcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIV
# yzCCFccCAQEwgZUwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAA
# AI6HkaRXGl/KPgAAAAAAjjANBglghkgBZQMEAgEFAKCBujAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkq
# hkiG9w0BCQQxIgQgSg+xMLfX+kOK+WSk1sAaNhr2nn7cf9HH7VILxcupl4AwTgYK
# KwYBBAGCNwIBDDFAMD6gJIAiAE0AaQBjAHIAbwBzAG8AZgB0ACAAQQBTAFAALgBO
# AEUAVKEWgBRodHRwOi8vd3d3LmFzcC5uZXQvIDANBgkqhkiG9w0BAQEFAASCAQBJ
# 2srUH6ry0PZw/mwC2en+IUqnrlK4reDM1Leln+Jq+pZNIzn+JTVU3Qx7Tw2Ycmvp
# XAPdTL2h1VlOEcqKJwrqg5U2PWlVuZ7PgpGkO8sIHRrx30G0hd7oFgjQhAgdYEEg
# YHpX7l50sH8Rt08dV5xKTNDCisUQl4GZUfWqCawhxVAY3nVXOEyexNnNX+TsWNmO
# g6LiCObgXim65QiCyWk4P6vmPn8+/0m/rlw7jaMK/OYhXoInBtEvRtQqCRcke5SS
# bwn2d2cw5ueP/EzAa4E0zSH0FR4QJz5I5saMGLkHhYqaqGELSFc/d23ADld9uhIz
# kVQ/uTVew5RxZSl8xAMDoYITSTCCE0UGCisGAQQBgjcDAwExghM1MIITMQYJKoZI
# hvcNAQcCoIITIjCCEx4CAQMxDzANBglghkgBZQMEAgEFADCCAToGCyqGSIb3DQEJ
# EAEEoIIBKQSCASUwggEhAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAE
# IKcYLcTj8KrY9Wl1mN+YWdtnybjNpXeO4vqoq6mJKe9eAgZZkiBITBgYEzIwMTcw
# ODE1MjAxMDM5LjU5N1owBIACAfSggbmkgbYwgbMxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIxJzAlBgNVBAsTHm5DaXBo
# ZXIgRFNFIEVTTjoxNDhDLUM0QjktMjA2NjElMCMGA1UEAxMcTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgU2VydmljZaCCDs8wggZxMIIEWaADAgECAgphCYEqAAAAAAACMA0G
# CSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3Jp
# dHkgMjAxMDAeFw0xMDA3MDEyMTM2NTVaFw0yNTA3MDEyMTQ2NTVaMHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAqR0NvHcRijog7PwTl/X6f2mUa3RUENWlCgCChfvtfGhLLF/Fw+Vhwna3
# PmYrW/AVUycEMR9BGxqVHc4JE458YTBZsTBED/FgiIRUQwzXTbg4CLNC3ZOs1nMw
# VyaCo0UN0Or1R4HNvyRgMlhgRvJYR4YyhB50YWeRX4FUsc+TTJLBxKZd0WETbijG
# GvmGgLvfYfxGwScdJGcSchohiq9LZIlQYrFd/XcfPfBXday9ikJNQFHRD5wGPmd/
# 9WbAA5ZEfu/QS/1u5ZrKsajyeioKMfDaTgaRtogINeh4HLDpmc085y9Euqf03GS9
# pAHBIAmTeM38vMDJRF1eFpwBBU8iTQIDAQABo4IB5jCCAeIwEAYJKwYBBAGCNxUB
# BAMCAQAwHQYDVR0OBBYEFNVjOlyKMZDzQ3t8RhvFM2hahW1VMBkGCSsGAQQBgjcU
# AgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8G
# A1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeG
# RWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jv
# b0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUH
# MAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2Vy
# QXV0XzIwMTAtMDYtMjMuY3J0MIGgBgNVHSABAf8EgZUwgZIwgY8GCSsGAQQBgjcu
# AzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL1BLSS9k
# b2NzL0NQUy9kZWZhdWx0Lmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwA
# XwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0B
# AQsFAAOCAgEAB+aIUQ3ixuCYP4FxAz2do6Ehb7Prpsz1Mb7PBeKp/vpXbRkws8LF
# Zslq3/Xn8Hi9x6ieJeP5vO1rVFcIK1GCRBL7uVOMzPRgEop2zEBAQZvcXBf/XPle
# FzWYJFZLdO9CEMivv3/Gf/I3fVo/HPKZeUqRUgCvOA8X9S95gWXZqbVr5MfO9sp6
# AG9LMEQkIjzP7QOllo9ZKby2/QThcJ8ySif9Va8v/rbljjO7Yl+a21dA6fHOmWaQ
# jP9qYn/dxUoLkSbiOewZSnFjnXshbcOco6I8+n99lmqQeKZt0uGc+R38ONiU9Mal
# CpaGpL2eGq4EQoO4tYCbIjggtSXlZOz39L9+Y1klD3ouOVd2onGqBooPiRa6YacR
# y5rYDkeagMXQzafQ732D8OE7cQnfXXSYIghh2rBQHm+98eEA3+cxB6STOvdlR3jo
# +KhIq/fecn5ha293qYHLpwmsObvsxsvYgrRyzR30uIUBHoD7G4kqVDmyW9rIDVWZ
# eodzOwjmmC3qjeAzLhIp9cAvVCch98isTtoouLGp25ayp0Kiyc8ZQU3ghvkqmqMR
# ZjDTu3QyS99je/WZii8bxyGvWbWu3EQ8l1Bx16HSxVXjad5XwdHeMMD9zOZN+w2/
# XU/pnR4ZOC+8z1gFLu8NoFA12u8JJxzVs341Hgi62jbb01+P3nSISRIwggTaMIID
# wqADAgECAhMzAAAAtEM6HP62ulKJAAAAAAC0MA0GCSqGSIb3DQEBCwUAMHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTE2MDkwNzE3NTY1OFoXDTE4MDkw
# NzE3NTY1OFowgbMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# DTALBgNVBAsTBE1PUFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjoxNDhDLUM0
# QjktMjA2NjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOCBT7u10TA6P4MAt8xWn/eb
# rLqzXWQRHoLWetfuIPuz0QgBY5dXp8LiTFaotVfboMbfs9EYsR5+kawZGVFtc/6e
# LW0kQiDEyO9GadBvHExhapQzD5Q+26JvJSq/GdLOAzpSFYBFZRv9z7X/N7JoZpll
# re7/voFNQ54LeAnWKo89irQHM9mwUCRR73/1JNQVDI92GNhWvLVtoyl02HUHSEAZ
# jmYYkQICcBtB2/knoRl1xpao+kEvu3rFNKYwoJeTxxpsAFqCtowAZ5LLzE3SbKnj
# xF55CwGVrqikuSL++UVeP30ZG2GcN3TZo1HF7kjZVDMUg1+y5w97sB/Jl76ZhXEC
# AwEAAaOCARswggEXMB0GA1UdDgQWBBQMk6tF1GwLdy/zK1fz6STEhwf0XzAfBgNV
# HSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVtVTBWBgNVHR8ETzBNMEugSaBHhkVo
# dHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNUaW1T
# dGFQQ0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAC
# hj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0YVBD
# QV8yMDEwLTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMA0GCSqGSIb3DQEBCwUAA4IBAQACtWFboKfSaqwmL7bCNKN0+6h7kLGCLaiJ
# El2k9oILWT0n53odeSz4y3LPR2vvb97rkm3ur/teoZGEeONfUXvElzHgUI3tupn3
# iCq/UWriI+Q3R91m4sWFCOz+dXHrem1JiSUhHZ2OFuRYpOaolbWbtJOhiiy4nCE6
# vAFRH5jgn/Pt6lDMuzeEKWrwImylT64TEXlmZHAnowz6tN5Mu1B+xJ9/6YFRBN6u
# FF/mDgwQgbpGrDtiEue10Qow8NMp7PrTcDFuCnokUcIi5g4it0NRqlNVIvUktefT
# dXgpoTpbaQrgrXyZz5+0kigHfqpwxDKGW0oO2ES29T5nH3nD8itToYIDeDCCAmAC
# AQEwgeOhgbmkgbYwgbMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xDTALBgNVBAsTBE1PUFIxJzAlBgNVBAsTHm5DaXBoZXIgRFNFIEVTTjoxNDhD
# LUM0QjktMjA2NjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaIlCgEBMAkGBSsOAwIaBQADFQAHwJWXri5ObsnTdfbZiVGYiyBtOqCBwjCBv6SB
# vDCBuTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UE
# CxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBOVFMgRVNOOjRERTktMEM1RS0zRTA5
# MSswKQYDVQQDEyJNaWNyb3NvZnQgVGltZSBTb3VyY2UgTWFzdGVyIENsb2NrMA0G
# CSqGSIb3DQEBBQUAAgUA3T2mTDAiGA8yMDE3MDgxNTE2NTY0NFoYDzIwMTcwODE2
# MTY1NjQ0WjB2MDwGCisGAQQBhFkKBAExLjAsMAoCBQDdPaZMAgEAMAkCAQACAUcC
# Af8wBwIBAAICGlowCgIFAN0+98wCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYB
# BAGEWQoDAaAKMAgCAQACAwehIKEKMAgCAQACAwehIDANBgkqhkiG9w0BAQUFAAOC
# AQEAjmdQstcKWzH1e0NXriq3/QT/4WcplPQealspljd2/E5rHg6PlOVcU/YbjZF2
# RzS0M+hlDIG5LIRGVftA+L0pfjrSW3jjfLXkmAaiw6mNjZHyqlaARx9HYSX3O6bG
# e2XqBxAsimPsAthZDGu9by2bX3J9oat+MFkfy/saL+rzfnUYdmnH8ZRhZmXr+aow
# z7yYiq+XIlfx2OphwcpAqsKIpzV4DVeyFn/JbVtjyDBBx6xGmmF1aftBx4XDTrDz
# Qol9i9yrgBxR/lbPlZi0RNCqNfyPrhSl0FIqsd3SwQ2T7/aqqefBbAp19ojwMOPH
# 6Y72MNdcsGNzKp/ZXyXeuD3nIzGCAvUwggLxAgEBMIGTMHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwAhMzAAAAtEM6HP62ulKJAAAAAAC0MA0GCWCGSAFlAwQC
# AQUAoIIBMjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkE
# MSIEICK3EigvhiXqx4AEgcQ9DHAlzKOXi7dJBm95QiipsptIMIHiBgsqhkiG9w0B
# CRACDDGB0jCBzzCBzDCBsQQUB8CVl64uTm7J03X22YlRmIsgbTowgZgwgYCkfjB8
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1N
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAALRDOhz+trpSiQAAAAAA
# tDAWBBRd5egLny2W1+m36qKEHoY+61NGHTANBgkqhkiG9w0BAQsFAASCAQA40Aei
# FGhbmMTFFuo9rkf5VADwfG9tb0hJHXmjb/cfqe30SdBWOIMtpLF+yqf6n+FGIT/x
# 0dMJKipjn+R03FCCa7Hop9j4vzQQjNj52+v8RrOsguD+27CA2w88ClAb6w9aI1TF
# 0E7TqBr0lv733sfkUo6YXIOKgd6FNvf+NATvg4b9rl8h8hH0QiEfPL3sogu/Xb97
# t2xcjgYFNcx2XKQfFrTuEEgV3d/wu8ejp8sU/pIoxZnXAdSm+mWdtgSLIBWkyHE0
# Pv1h9A4NizBkBWrTWVus8LvDTujzYV7dq9/Iwl304cG1eOCFZuuTrIlErlJj7lt7
# 4ePx6td2KFT2aruY
# SIG # End signature block
