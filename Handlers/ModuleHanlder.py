import yaml

from Handlers.IHandler import IHandler
from Handlers.XmlHandler import XmlHandler
from appConfig.Module import Module

import xml.etree.cElementTree as ET


def loadConfig(AppPatch):
    with open(AppPatch + "/appConfig/config.yaml") as fp:
        return yaml.load(fp)


class ModuleHandler(IHandler):
    INDEX_HANDLER = 0
    INDEX_TAG_PROVIDER = 1
    INDEX_PATH = 2

    def __init__(self, AppPatch):

        def loadXmlProviders():
            provider = self.configuration["tagProvider"]

            for providerFileName, valueProvider in provider.iteritems():
                handler = XmlHandler(XmlHandler.XmlType.PARSER, self)
                root = ET.fromstring(valueProvider["tag"])
                self.xmlFileProvider[providerFileName] = [handler, root, valueProvider["path"]]

            modTest = Module("moduleTest", "192.168.101.01", "/home/nicoblues/workspaceSVN/Lafont/Codigo/LafontWEB",
                             "FAF12_LAFONT", "sa", "Pentatonica_2016",
                             "/home/nicoblues/workspaceSVN/Lafont/Codigo/Resource")

            self.addModule(modTest)

        self.configuration = loadConfig(AppPatch)

        self.configFolderPath = self.configuration["configFile"]
        self.workSpaceFolders = self.configuration["workSpaceFolders"]
        self.xmlFileProvider = {}

        self.currentProvider = ''

        loadXmlProviders()

    def meshModuleWithProvider(self, module, provider):

        def replace(tagValue):
            retVal = tagValue
            for keyConfig, value in module.moduleConfig.iteritems():
                if tagValue.find(keyConfig) != -1:
                    retVal = str.replace(retVal, keyConfig, value, 1)

            return retVal

        for element in provider.iter():
            if element.attrib is not None:
                for key, value in element.attrib.iteritems():
                    element.attrib[key] = replace(value)
            element.text = replace(element.text)

        # if provider.find("jndi-name") is not None:
        #     for element in provider.iter():
        #         element.text = replace(element.text)
        #         # provider.find("jndi-name").text = replace(provider.find("jndi-name").text)
        #         # provider.find("connection-url").text = replace(provider.find("connection-url").text)
        #
        # elif provider.find("FAFModule") is not None:
        #     pass
        # elif provider.find("FAFEmpresa") is not None:
        #     pass

    def addModule(self, module):
        for providerName, valueProvider in self.xmlFileProvider.iteritems():
            self.currentProvider = providerName
            xmlHandler = valueProvider[self.INDEX_HANDLER]
            xmlHandler.toDo()

            tagProvider = valueProvider[self.INDEX_TAG_PROVIDER]

            self.meshModuleWithProvider(module, tagProvider)
            xmlHandler.addElement(tagProvider)
            xmlHandler.writeFile(indetFile=True)

    def getPath(self):
        if self.currentProvider == '':  # TODO cambiar este parche mugroso
            return ""
        else:
            return self.xmlFileProvider[self.currentProvider][self.INDEX_PATH]
