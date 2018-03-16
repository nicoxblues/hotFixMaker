from enum import Enum

from Handlers.DefaultParserHandler import DefaultParserHandler
from Handlers.IHandler import IHandler
import xml.etree.cElementTree as ET


class XmlHandler(IHandler):

    class XmlType(Enum):
        MBU_MAIN = 1
        PARSER = 2

    def __init__(self, fileTy, handler, parseHandler=None):



        self.calledHandler = handler
        self.xmlTy = fileTy
        # TODO esto es un asco esta muy mal, hay que cambiarlo esta mal que el constructor sepa que es un mbu.xml
        self.mainXmlPath = handler.getPath() + 'mbu.xml'
        self.parseHandler = parseHandler


    def setFileName(self, fileName):
        pass

    def getPath(self):  # lo imagine mas complicado de lo que en realidad es
        return self.calledHandler.getPath()

    def toDo(self):
        if self.xmlTy == self.XmlType.MBU_MAIN:
            self.createXmlFile()

        if self.xmlTy == self.XmlType.PARSER:
            self.parse()

    def parse(self):

        if self.parseHandler is None:
            tree = ET.parse(self.getPath())
            root = tree.getroot()
            self.parseHandler = DefaultParserHandler(root)


    def addElement(self, element):
        self.parseHandler.addElement(element)


    def writeFile(self, indetFile= False):

        fileMainRoot  = self.parseHandler.getMainRoot()
        tree = ET.ElementTree(fileMainRoot)

        if indetFile:
            self.indent(fileMainRoot)


        tree.write(self.calledHandler.getPath(), encoding="utf-8", method="xml", xml_declaration=True)

    def indent(self, elem, level=0):
        i = "\n" + level * "  "
        if len(elem):
            if not elem.text or not elem.text.strip():
                elem.text = i + "  "
            if not elem.tail or not elem.tail.strip():
                elem.tail = i
            for elem in elem:
                self.indent(elem, level + 1)
            if not elem.tail or not elem.tail.strip():
                elem.tail = i
        else:
            if level and (not elem.tail or not elem.tail.strip()):
                elem.tail = i

    def createXmlFile(self):
        print self.calledHandler.getPath()



        root = ET.Element("config")
        ET.SubElement(root, "version").text = "1.0.13.55"
        ET.SubElement(root, "app").text = "BSA"
        ET.SubElement(root, "extraMails").text = " "

        xmlCount = ET.SubElement(root, "xmlcount")

        internalHandler = XmlHandler(self.XmlType.PARSER, self)

        internalHandler.setFileName("clasesVO.xml")
        internalHandler.toDo()
        internalHandler.parseHandler.getTagCounter("fafClass")
        tagvo = ET.SubElement(xmlCount, "vo")
        taghlp = ET.SubElement(xmlCount, "hlp")

        tagvo.text = str(0)
        taghlp.text = str(0)

        moduleTag = ET.SubElement(root, "module")
        ET.SubElement(moduleTag, "moduleName").text = "INTERELECAPP"
        ET.SubElement(moduleTag, "cleaningModule").text = "false"
        ET.SubElement(root, "dependencias")

        self.indent(root)

        tree = ET.ElementTree(root)

        tree.write(self.calledHandler.getPath() + "mbu.xml", encoding="utf-8", method="xml", xml_declaration=True)
