import pymssql

import os

from Handlers.FileHandler import FileHandler

# /FAF12_DESARROLLO;instance=DESARROLLO_2016
#
# conn = pymssql.connect(server='192.168.202.80', user='sa', password='clave_2016', database='FAF12_DESARROLLO')
#
#
# cursor = conn.cursor()
# cursor.execute('Select * from FAFconfig')
# row = cursor.fetchone()
# while row:
#     print str(row[0]) + " " + str(row[1]) + " " + str(row[2])
#     row = cursor.fetchone()


moduleName = "INTERAPP"
modulePath = "/home/administrador/workingSpace/Interelec"
hotFixPath = "/home/administrador/hotfix/"
resourcesPath = "/home/administrador/workingSpace/Interelec/Resource"


fileH = FileHandler(11, moduleName, modulePath, hotFixPath, resourcesPath)
AppPatch = os.path.dirname(os.path.abspath(__file__))
fileH.createHotFixFolder(patch=AppPatch)
