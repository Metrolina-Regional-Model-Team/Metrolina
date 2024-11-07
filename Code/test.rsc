folder = RunMacro("G30 Tutorial Folder")

absolute_path = GetAbsolutePath(folder, "MasterLinks.DBD")

ShowMessage("The absolute pathname for " + file_name + " is " + absolute_path)

