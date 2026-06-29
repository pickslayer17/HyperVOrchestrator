using System.Text;

namespace Orchestrator.Helpers;

internal static class FileHelper
{
    public static string ReadText(string path)
    {
        var result = File.ReadAllText(path);
        return result;
    }

    public static string WriteTempScript(string scriptText)
    {
        var tempPath = Path.Combine(Path.GetTempPath(), $"orch-{Guid.NewGuid():N}.ps1");
        var encoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier: true);
        File.WriteAllText(tempPath, scriptText, encoding);
        return tempPath;
    }

    public static void DeleteTempScript(string path)
    {
        if (File.Exists(path))
            File.Delete(path);
    }
}
