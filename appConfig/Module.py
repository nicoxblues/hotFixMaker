class Module:

    def __init__(self, moduleName, host, webPath, DBName, user, passw, resourcePath):

        self.moduleConfig = {'RESOURCE_PATH': resourcePath, 'MODULE_WEB': webPath, 'MODULE_NAME': moduleName,
                             'MODULE_HOST_SERVER': host, 'BASE_NAME': DBName, 'SQL_USER': user, 'USER_PASS': passw}
        # self.moduleName = moduleName
        # self.host = host
        # self.webPath = webPath
        # self.sqlDBName = DBName
        # self.sqlUserName = user
        # self.passw = passw
