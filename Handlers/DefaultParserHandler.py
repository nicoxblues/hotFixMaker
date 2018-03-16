class DefaultParserHandler:

    def __init__(self, root):
        self.root = root

    def getTagCounter(self, tagName):
        return sum(1 for _ in self.root.iter(tagName))

    def getValueTag(self, tagName, attrName=None):
        pass

    def findLastTagFromName(self, tagName):
        return self.root.find(tagName)

    def addElement(self, element):
        self.root.append(element)

    def getMainRoot(self):
        return self.root
