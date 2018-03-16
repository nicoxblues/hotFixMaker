import subprocess
import os
import xml.etree.cElementTree as ET
import shutil

from Handlers.XmlHandler import XmlHandler
from Handlers.IHandler import IHandler


class FileHandler(IHandler):
    def __init__(self, days, moduleName, modulePath, hfPath, fafReport):

        self.xmlName = []
        self.days = days
        self.moduleName = moduleName
        self.modulePath = modulePath
        self.hfPath = hfPath
        self.reportPath = fafReport
        self.outputModule = []
        self.outputCodeFile = []
        self.extension = {'xml': [],
                          'js': [],
                          'sql': []}

        self.folderForExtension = {'xml': hfPath + 'views',
                                   'js': hfPath + 'WebHomeDeploy/general',
                                   'sql': hfPath + 'sql/'}

    def getPath(self):
        return self.getHFPath()

    def getHFPath(self):
        return self.hfPath

    def getDays(self):
        return self.days

    def getPatchModule(self):
        return self.modulePath

    def getReportRoot(self):
        return self.reportPath

    def createHotFixFolder(self, patch=os.path.dirname(os.path.abspath(__file__))):

        self.setRealPath(patch)
        self.createFolder()

        hanlderxml = XmlHandler(XmlHandler.XmlType.MBU_MAIN, self)
        hanlderxml.setFileName("clasesVO.xml")
        hanlderxml.toDo()






    def setRealPath(self,patch):

        processCodeFiles = subprocess.Popen(
            ['bash', patch + '/static/findFile.sh', str(self.getDays()),
             str(self.getPatchModule())],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        rowOutputCodeFile, err = processCodeFiles.communicate()

        print rowOutputCodeFile
        if err is not None:
            self.outputCodeFile = rowOutputCodeFile.splitlines()

        for line in self.outputCodeFile:
            fileListExtension = self.extension[line[line.rfind(".") + 1:]]
            fileListExtension.append(line)

    def createFolder(self):
        for key, value in self.extension.iteritems():
            for fileSrc in value:
                dstFolder = self.folderForExtension[key]
                if key == 'xml':
                    if fileSrc.find('clases') != -1:
                        dstFolder = self.getHFPath()
                        self.xmlName.append(os.path.basename(fileSrc))
                    else:
                        dstFolder += fileSrc[fileSrc.find(self.moduleName) + len(self.moduleName):fileSrc.rfind("/") + 1]

                if key == 'js':
                    dstFolder += fileSrc[fileSrc.find('general') + len('general'):fileSrc.rfind("/") + 1]

                if not os.path.exists(dstFolder):
                    os.makedirs(dstFolder)

                shutil.copy2(fileSrc, dstFolder)

    def createViewReport(self):

        def indent(elem, level=0):
            i = "\n" + level * "  "
            if len(elem):
                if not elem.text or not elem.text.strip():
                    elem.text = i + "  "
                if not elem.tail or not elem.tail.strip():
                    elem.tail = i
                for elem in elem:
                    indent(elem, level + 1)
                if not elem.tail or not elem.tail.strip():
                    elem.tail = i
            else:
                if level and (not elem.tail or not elem.tail.strip()):
                    elem.tail = i

        root = ET.Element("root")
        # doc = ET.SubElement(root, "files")

        tree = ET.ElementTree(root)

        for line in self.extension['xml']:
            if line is not None:
                print line
                indexFafReport = line.find("fafReport")
                if indexFafReport != -1:
                    ET.SubElement(root, "file", ).text = line[indexFafReport:]

                    # ****************** xml creator

                    # os.makedirs(self.getHFPath() + "test/test1/subDir")
                    #
        if len(self.extension['xml']) > 0:
            indent(root)
            tree.write(self.folderForExtension['xml'] + "/files.xml", encoding='utf-8', method="xml", xml_declaration=True)
