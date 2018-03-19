import yaml

from Handlers.IHandler import IHandler
from Handlers.XmlHandler import XmlHandler
from appConfig.Module import Module

import sys
import os

import xml.etree.cElementTree as ET


# TODO esto deberia estar en una clase singleton aparte, la cual pueda persistir, pero por ahora la config es manual
def loadConfig(root_path_app):
    with open(root_path_app + "/appConfig/config.yaml") as fp:
        return yaml.load(fp)


class ModuleHandler(IHandler):
    INDEX_HANDLER = 0
    INDEX_TAG_PROVIDER = 1
    INDEX_PATH = 2

    def __init__(self):
        app_root_path = os.path.dirname(getattr(sys.modules['__main__'], '__file__'))

        self.moduleCacheList = []

        def loadXmlProviders():
            provider = self.configuration["tagProvider"]

            for providerFileName, valueProvider in provider.iteritems():
                handler = XmlHandler(XmlHandler.XmlType.PARSER, self)
                root = ET.fromstring(valueProvider["tag"])
                self.xmlFileProvider[providerFileName] = [handler, root,
                                                          valueProvider["path"][0] + valueProvider["path"][1]]
                self.currentProvider = providerFileName
                handler.toDo()

        def createCacheModules():
            moduleProvider = self.xmlFileProvider["fafmodules"]
            elementModuleList = moduleProvider[self.INDEX_HANDLER].parseHandler.getElementList("FAFModule")
            for moduleElement in elementModuleList:
                self.moduleCacheList.append(moduleElement.attrib["name"])

        self.configuration = loadConfig(app_root_path)

        self.configFolderPath = self.configuration["configFile"]
        self.workSpaceFolders = self.configuration["workSpaceFolders"]
        self.xmlFileProvider = {}

        self.currentProvider = ''

        loadXmlProviders()
        createCacheModules()

    def meshModuleWithProvider(self, module, provider, xmlHandler):

        def replace(tagValue):
            retVal = tagValue
            for keyConfig, value in module.moduleConfig.iteritems():
                if keyConfig != 'DEPENDENCES':
                    if tagValue.find(keyConfig) != -1:
                        retVal = str.replace(retVal, keyConfig, value, 1)

            return retVal

        for element in provider.iter():
            if str(element).find("ModuleDependencie") == -1:
                if element.attrib is not None:
                    for key, value in element.attrib.iteritems():
                        if key == 'moduleDeployOrder':
                            val = xmlHandler.getValueAttr("FAFModule", key)
                            element.attrib[key] = str(int(val) + 1)
                        else:

                            element.attrib[key] = replace(value)

                element.text = replace(element.text)

                if str(element).find("FAFEmpresa") != -1:
                    for dep in module.moduleConfig["DEPENDENCES"]:
                        # ET.SubElement(element, dep)
                        element.append(dep)

    def addModule(self, module):
        module.moduleConfig["JBOSS_PATH"] = self.configuration.get("configFile").get("jbossFolder")
        for providerName, valueProvider in self.xmlFileProvider.iteritems():
            # self.currentProvider = providerName
            # xmlHandler = valueProvider[self.INDEX_HANDLER]
            # xmlHandler.toDo()

            tagProvider = valueProvider[self.INDEX_TAG_PROVIDER]

            self.meshModuleWithProvider(module, tagProvider, xmlHandler)
            xmlHandler.addElement(tagProvider)
            xmlHandler.writeFile(indetFile=True)

    def getPath(self):
        if self.currentProvider == '':  # TODO cambiar este parche mugroso
            return ""
        else:
            return self.xmlFileProvider[self.currentProvider][self.INDEX_PATH]
