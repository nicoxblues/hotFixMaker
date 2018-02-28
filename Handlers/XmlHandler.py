from enum import Enum, unique

from Handlers.IHandler import IHandler
import xml.etree.cElementTree as ET


class XmlHandler(IHandler):
    @unique
    class XmlType(Enum):
        MBU_MAIN = 1
        VO_HLP_TAG_HANDLER = 2

    def __init__(self, fileTy, handler):

        self.tagCounter = 0
        self.calledHandler = handler
        self.xmlTy = fileTy
        self.mainXmlPath = handler.getPath() + 'mbu.xml'

    def setFileName(self, fileName):
        self.fileName = fileName

    def getPath(self):  # lo imagine mas complicado de lo que en realidad es
        return self.calledHandler.getPath()

    def toDo(self):
        if self.xmlTy == self.XmlType.MBU_MAIN:
            self.createXmlFile()

        if self.xmlTy == self.XmlType.VO_HLP_TAG_HANDLER:
            self.parse()

    def parse(self):
        tree = ET.parse(self.getPath() + self.fileName)
        root = tree.getroot()
        self.tagCounter = sum(1 for _ in root.iter("fafClass"))

    def createXmlFile(self):
        print self.calledHandler.getPath()

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

        root = ET.Element("config")
        ET.SubElement(root, "version").text = "1.0.13.55"
        ET.SubElement(root, "App").text = "BSA"
        ET.SubElement(root, "extraMails").text = "BSA"

        xmlCount = root.makeelement('xmlCount', {})

        internalHandler = XmlHandler(self.XmlType.VO_HLP_TAG_HANDLER, self)

        internalHandler.setFileName("clasesVO.xml")
        internalHandler.toDo()


        tagvo = ET.SubElement(xmlCount, "vo")


        tagvo.text = internalHandler.tagCounter
        indent(root)


        # internalHandler.setFileName("clasesHLP.xml")
        # internalHandler.toDo()
        # ET.SubElement(xmlCount, "hlp").text = internalHandler.tagCounter







        tree.write(self.calledHandler.getPath() + "mbu.xml", encoding='utf-8', method="xml")
