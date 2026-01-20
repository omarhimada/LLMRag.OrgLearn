# Create project directory
$projectDir = "CodeCombiner"
New-Item -ItemType Directory -Path $projectDir | Out-Null
Set-Location $projectDir

# Create new console app (creates Program.cs with template content)
dotnet new console -n CodeCombinerApp

# Define the full program code (this would be your complete code from earlier)
$programCode = @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

class FileInfoEntry
{
    public string OriginalPath { get; set; }
    public string ConvertedPath { get; set; }
    public string FileExtension { get; set; } // stores original extension without dot
}

public class CodeFileConverter
{
    private readonly HashSet<string> _codeExtensions = new HashSet<string>
    {
        ".cs", ".vb", ".js", ".ts", ".py", ".java", ".cpp", ".c", ".h", ".hpp"
    };

    public List<FileInfoEntry> ConvertFilesToTxt(string rootDirectory)
    {
        var fileList = new List<FileInfoEntry>();

        foreach (var filePath in Directory.EnumerateFiles(rootDirectory, "*", SearchOption.AllDirectories))
        {
            string extension = Path.GetExtension(filePath).ToLower();
            if (_codeExtensions.Contains(extension))
            {
                
                string convertedPath = Path.ChangeExtension(filePath, ".txt");
                File.Copy(filePath, convertedPath, true);

                var entry = new FileInfoEntry
                {
                    OriginalPath = filePath,
                    ConvertedPath = convertedPath,
                    FileExtension = extension.Substring(1)
                };
                fileList.Add(entry);
            }
        }

        return fileList;
    }
}

public class CodeCombiner
{
    public string CombineFiles(List<FileInfoEntry> fileList, string outputPath)
    {
        var result = new StringBuilder();

        foreach (var file in fileList)
        {
            if (!File.Exists(file.ConvertedPath))
                continue;

            string content = File.ReadAllText(file.ConvertedPath);

            // Add distinguishing comment between files
            if (result.Length > 0)
            {
                result.AppendLine();
                result.AppendLine(GetDistinguishingComment(file.FileExtension));
                result.AppendLine();
            }

            result.AppendLine(content);
        }

        [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName(outputPath))
        File.WriteAllText(outputPath, result.ToString())
        return outputPath
    }

    private string GetDistinguishingComment(string fileType)
    {
        switch (fileType.ToLower())
        {
            case "cs":
                return "/* ========================================================================================================================= */";
            case "vb":
                return "' ========================================================================================================================== ";
            case "js":
            case "ts":
                return "// =========================================================================================================================== ";
            case "py":
                return "# ============================================================================================================================ ";
            case "java":
                return "/** ========================================================================================================================= */";
            default:
                return "// =========================================================================================================================== ";
        }
    }
}

class Program
{
    static void Main(string[] args)
    {
        // Omitted
    }
}
"@

# Replace the generated Program.cs with our full code
$programCsPath = Join-Path $projectDir CodeCombinerApp Program.cs
Set-Content -Path $programCsPath -Value $programCode -Force

# Build the application (this will use the .NET CLI)
dotnet build

Write-Host "Build completed. To run, use:"
Write-Host "  dotnet run --path $projectDir -- <your_source_directory>"
