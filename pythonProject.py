from FileHandler import FileHandler


moduleName = "INTERAPP"
modulePath = "/home/nicoblues/workspaceSVN/Interelec"
hotFixPath = "/home/nicoblues/hotfix/"
resourcesPath = "/home/nicoblues/workspaceSVN/Interelec/Resource"


fileH = FileHandler(10, moduleName, modulePath, hotFixPath, resourcesPath)

fileH.createHotFixFolder()
