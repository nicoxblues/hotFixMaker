from FileHandler import FileHandler


moduleName = "Interelec"
modulePath = "/home/administrador/workingSpace/Interelec"
hotFixPath = "/home/administrador/HotFix/"
resourcesPath = "/home/administrador/workingSpace/Interelec/Resource"


fileH = FileHandler(12, moduleName, modulePath, hotFixPath, resourcesPath)

fileH.createHotFixFolder()
