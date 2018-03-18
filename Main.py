from Tkinter import *
from tkFileDialog import askopenfilename

import os

from appConfig.Module import Module
from Handlers.ModuleHanlder import *
import ttk


class AppIU:

    def __init__(self):
        self.root = Tk()
        self.createMenu()

        self.root.minsize(800,600)

        self.module = ModuleHandler()

        self.root.tableview()
        self.comboModules = ttk.Combobox(self.root, state="readonly")
        self.newModuleName = ttk.Entry(self.root)

        self.comboModules['values'] = self.module.moduleCacheList
        self.comboModules.current(0)
        ttk.Label(self.root, text="add dependence module :").grid(column=0, row=0)
        ttk.Label(self.root, text="nombre del modulo :").grid(column=0, row=3)
        self.comboModules.grid(column=3, row=0)
        self.newModuleName.grid(column=3, row=3)
        # modTest = Module("moduleTest", "192.168.101.01", "/home/nicoblues/workspaceSVN/Lafont/Codigo/LafontWEB",
        #                   "FAF12_LAFONT", "sa", "Pentatonica_2016",
        #                   "LAFONTAPP", dependences=[])
        #
        # self.module.addModule(modTest)


    def createMenu(self):
        def NewFile():
            print "New File!"

        def OpenFile():
            name = askopenfilename()
            print name

        def About():
            print "This is a simple example of a menu"

        def addModule():
            # create window module
            pass


        menu = Menu(self.root)
        self.root.config(menu=menu)
        filemenu = Menu(menu)
        menu.add_cascade(label="File", menu=filemenu)
        filemenu.add_command(label="New", command=NewFile)
        filemenu.add_command(label="Open...", command=OpenFile)
        filemenu.add_separator()
        filemenu.add_command(label="Exit", command=self.root.quit)

        helpmenu = Menu(menu)
        menu.add_cascade(label="Help", menu=helpmenu)
        helpmenu.add_command(label="About...", command=About)


def main():
    app = AppIU()
    app.root.mainloop()
    return 0


if __name__ == "__main__":
    main()
