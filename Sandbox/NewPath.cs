//Code by Emanuel Granados (copied from one of his modules)

private const string FilesRelativePath = "/Files/Documents";

private string GetDocumentAbsolutePath(string fileName, DateTime date)
{
    var relativepath = string.Format("{0}/{1}/{2}/", FilesRelativePath, date.Year, date.Month);
    return HttpContext.Current.Server.MapPath(relativepath);
}

var absolutepath = GetDocumentAbsolutePath(file.FileName, date);
    var completePath = absolutepath + file.FileName; 

    if (!Directory.Exists(absolutepath))
        Directory.CreateDirectory(absolutepath);

    file.SaveAs(completePath);