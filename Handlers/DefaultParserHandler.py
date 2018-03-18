class DefaultParserHandler:

    def __init__(self, root):
        self.root = root

    def getTagCounter(self, tagName):
        return sum(1 for _ in self.root.iter(tagName))

    def setAttr(self, tagName, value, attrName=None):
        self.findLastTagFromName(tagName)[attrName] = value

    def getAttr(self, tagName, attrName=None):
        return self.findLastTagFromName(tagName).attrib[attrName]

    def findLastTagFromName(self, tagName):
        return self.root.find(tagName + '[last()]')

    def addElement(self, element):
        self.root.append(element)

    def getMainRoot(self):
        return self.root

    def getElementList(self, tagName):
        element_list = []
        for element in self.root.iter(tagName):
            element_list.append(element)

        return element_list
