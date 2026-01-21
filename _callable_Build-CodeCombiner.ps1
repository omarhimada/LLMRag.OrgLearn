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

class Program {
	static void Main(string[] args) {
		string currentDirectory = Directory.GetCurrentDirectory();

		string targetDirectory = Path.Combine(currentDirectory, "Repos");
		CodeFileConverter cfc = new();
		List<FileInfoEntry> list = cfc.ConvertFilesToTxt(targetDirectory);

		List<FileInfoEntry> fileList = list;
		Console.WriteLine($"{cfc.GetType().Name} created with extension list {string.Join("	", cfc._codeExtensions)}");

		CodeCombiner combiner = new();
		string outputPath = combiner.CombineFiles(fileList, "combined_output.txt");

		Console.WriteLine($"Combined file created at: {outputPath}");

		Console.WriteLine("Process completed successfully.");
		Console.WriteLine("Press any key to exit. combined_output.txt has been created.");
		
		Console.ReadLine();
	}
}

internal class CodeFileConverter {
	internal readonly HashSet<string> _codeExtensions =
	[
		".cs", ".vb", ".js", ".ts", ".py", ".java", ".cpp", ".c", ".h", ".hpp"
	];

	internal List<FileInfoEntry> ConvertFilesToTxt(string rootDirectory) {
		List<FileInfoEntry> fileList = [];

		foreach (string filePath in Directory.EnumerateFiles(rootDirectory, "*", SearchOption.AllDirectories)) {
			string extension = Path.GetExtension(filePath).ToLower();
			if (_codeExtensions.Contains(extension)) {
				string convertedPath = Path.ChangeExtension(filePath, ".txt");
				File.Copy(filePath, convertedPath, true);

				FileInfoEntry entry = new() {
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

internal class CodeCombiner {
	internal string CombineFiles(List<FileInfoEntry> fileList, string outputPath) {
		StringBuilder result = new();

		foreach (FileInfoEntry file in fileList) {
			if (!File.Exists(file.ConvertedPath))
				continue;

			string content = File.ReadAllText(file.ConvertedPath);

			// Add distinguishing comment between files
			if (result.Length > 0) {
				_ = result.AppendLine();
				_ = result.AppendLine(GetDistinguishingComment(file.FileExtension));
				_ = result.AppendLine();
			}

			_ = result.AppendLine(content);
		}

		File.WriteAllText(outputPath, result.ToString());
		return outputPath;
	}

	internal string GetDistinguishingComment(string fileType) => fileType.ToLower() switch {
		"cs" => "/* ========================================================================================================================= */",
		"vb" => "' ========================================================================================================================== ",
		"js" or "ts" => "// =========================================================================================================================== ",
		"py" => "# ============================================================================================================================ ",
		"cpp" => "/* ========================================================================================================================= */",
		"c" => "/* ========================================================================================================================= */",
		"h" => "/* ========================================================================================================================= */",
		"java" => "/** ========================================================================================================================= */",
		_ => "// =========================================================================================================================== ",
	};
}

internal class FileInfoEntry {
	internal required string OriginalPath { get; set; }
	internal required string ConvertedPath { get; set; }
	internal required string FileExtension { get; set; }
}
"@

# Replace the generated Program.cs with our full code
$cc = "CodeCombiner"
$appPath = "CodeCombinerApp"
$programDirectory = Join-Path -Path $cc $appPath
$programCs = Join-Path -Path $programDirectory "Program.cs"

cd ../

Set-Content -Path $programCs -Value $programCode -Force

$csproj = ".\$programDirectory\CodeCombinerApp.csproj"

# Build the application (this will use the .NET CLI)
dotnet build --configuration Release $csproj

Write-Host $PWD

dotnet run --project $csproj