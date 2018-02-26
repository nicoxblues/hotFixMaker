import subprocess
import os
import xml.etree.cElementTree as ET
import shutil


class FileHandler:
    def __init__(self, days, moduleName, modulePath, hfPath, fafReport):
        self.days = days
        self.moduleName = moduleName
        self.modulePath = modulePath
        self.hfPath = hfPath
        self.reportPath = fafReport
        self.outputModule = []
        self.outputCodeFile = []
        pathMap = {'realPath': [], 'relativePath': []}
        # TODO debe haber una mejor maenera de hacer esto !
        self.filePath = {'fafReport': {'realPath': [], 'relativePath': []},
                         moduleName + 'Web': {'realPath': [], 'relativePath': []},
                         'Script': {'realPath': [], 'relativePath': []}}

    def getHFPath(self):
        return self.hfPath

    def getDays(self):
        return self.days

    def getPatchModule(self):
        return self.modulePath

    def getReportRoot(self):
        return self.reportPath

    def createHotFixFolder(self):
        self.setRealPath()
        self.createFolder()

        self.createViewReport()

    def setRealPath(self):

        processViewReport = subprocess.Popen(
            ['bash', os.path.dirname(os.path.abspath(__file__)) + '/static/findFile.sh', str(self.getDays()),
             str(self.getPatchModule())],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        processCodeFiles = subprocess.Popen(
            ['bash', os.path.dirname(os.path.abspath(__file__)) + '/static/findFile.sh', str(self.getDays()),
             str(self.getPatchModule())],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        rowOutputReport, err = processViewReport.communicate()

        if err is not None:
            self.outputModule = rowOutputReport.splitlines()

        rowOutputCodeFile, err = processCodeFiles.communicate()

        if err is not None:
            self.outputCodeFile = rowOutputCodeFile.splitlines()

        for line in self.outputModule:
            for key, _ in self.filePath.iteritems():
                if key is not None:
                    indexPathKey = line.find(key)
                    if indexPathKey == -1:
                        pass
                    else:
                        self.filePath[key]['relativePath'].append(line[indexPathKey:])
                        self.filePath[key]['realPath'].append(line)
                        break

    def createFolder(self):
        for value in self.filePath.values():
            relativePath = value['relativePath']
            realP = value['realPath']
            indexPath = 0
            for pathValue in relativePath:
                pathValue = pathValue.replace(self.moduleName + "WEB", "WebHomeDeploy")
                fileName = pathValue[pathValue.rfind("/") + 1:]
                folderPath = pathValue[:pathValue.rfind("/")]
                if not os.path.exists(self.getHFPath() + folderPath):
                    os.makedirs(self.getHFPath() + folderPath)

                shutil.copy2(realP[indexPath], self.getHFPath() + folderPath + "/" + fileName)
                indexPath += 1

    def createViewReport(self):

        root = ET.Element("root")
        # doc = ET.SubElement(root, "files")

        tree = ET.ElementTree(root)

        for line in self.filePath['fafReport']['relativePath']:
            if line is not None:
                print line
                indexFafReport = line.find("fafReport")

                ET.SubElement(root, "file", ).text = line[indexFafReport:]

                # ****************** xml creator

                # os.makedirs(self.getHFPath() + "test/test1/subDir")
                #
        if len(self.filePath['fafReport']['relativePath']) > 0:
            tree.write(self.getHFPath() + "fafReport/file.xml")
