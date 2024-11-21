# Define the input file path
$filePath = "C:\Users\jeff.parker\Downloads\isi_smb_info_11-19-2024.log"  # Replace with your file's path

# Define the output file path with the current date
$date = Get-Date -Format "yyyyMMdd"
$outputFilePath = "C:\Users\jeff.parker\Downloads\isi_$date.csv"

# Read all lines from the file
$fileContent = Get-Content -Path $filePath

# Initialize an array to store results
$results = @()

# Iterate through lines in the file
for ($i = 1; $i -lt $fileContent.Length; $i++) {
    # Check if the current line starts with "Path:" and contains the word "firework"
    if ($fileContent[$i] -match "Path:") {
        # Add the previous line and the current line to the results array
        $results += [PSCustomObject]@{
            "PreviousLine" = $fileContent[$i - 1].Trim()
            "MatchingLine" = $fileContent[$i].Trim()
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputFilePath -NoTypeInformation -Encoding UTF8

# Notify the user
Write-Host "Results saved to $outputFilePath"