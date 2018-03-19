import tkFont
from Tkinter import *
from tkFileDialog import askopenfilename
from appConfig.Module import Module

from Handlers.ModuleHanlder import *
import ttk


class AppIU:

    def __init__(self):
        self.root = Tk()
        self.createMenu()

        self.root.minsize(800, 600)

        self.module = ModuleHandler()
        self._load_widgets()
        self._build_tree()

    def _load_widgets(self):
        self.comboModules = ttk.Combobox(self.root, state="readonly")
        self.comboModules.bind("<<ComboboxSelected>>", self.addItem)
        self.newModuleName = ttk.Entry(self.root)

        self.comboModules['values'] = self.module.moduleCacheList
        self.comboModules.current(0)
        ttk.Label(self.root, text="add dependence module :").grid(column=0, row=0)
        ttk.Label(self.root, text="nombre del modulo :").grid(column=0, row=3)
        self.comboModules.grid(column=3, row=0)
        self.newModuleName.grid(column=3, row=3)

        self.tree = ttk.Treeview(columns=["dependencias"], show="headings")

        def delItemTree(item_to_delete):
            self.tree.itemsTree[self.tree.item(item_to_delete)["values"][0]] = None
            self.tree.delete(item_to_delete)

        def addItemTree(item_to_add):
            if self.tree.itemsTree.get(item_to_add) is None:
                self.tree.itemsTree[item_to_add] = self.tree.insert('', 'end', values=item_to_add)


        self.tree.itemsTree = {"delItem": delItemTree, "addItem": addItemTree}
        self.tree.bind("<KeyPress>", self.deleteItem)

        vsb = ttk.Scrollbar(orient="vertical",
                            command=self.tree.yview)
        hsb = ttk.Scrollbar(orient="horizontal",
                            command=self.tree.xview)

        self.tree.configure(yscrollcommand=vsb.set,
                            xscrollcommand=hsb.set)

        self.tree.grid(column=0, row=10, sticky='nsew', in_=self.root)
        vsb.grid(column=1, row=10, sticky='ns', in_=self.root)
        hsb.grid(column=0, row=11, sticky='ew', in_=self.root)

        # modTest = Module("moduleTest", "192.168.101.01", "/home/nicoblues/workspaceSVN/Lafont/Codigo/LafontWEB",
        #                   "FAF12_LAFONT", "sa", "Pentatonica_2016",
        #                   "LAFONTAPP", dependences=[])
        #
        # self.module.addModule(modTest)

    def deleteItem(self, e):
        if e.keycode == 119:
            for selected_item in self.tree.selection():
                self.tree.itemsTree["delItem"](selected_item)
                # self.tree.diccItems[self.tree.item(selected_item)["values"][0]] = None
                # self.tree.delete(selected_item)

    def addItem(self, e):
        moduleItem = self.comboModules.get()
        self.tree.itemsTree["addItem"](moduleItem)


    def _build_tree(self):
        for col in ["dependencias"]:
            self.tree.heading(col, text=col.title(),
                              command=lambda c=col: sortby(self.tree, c, 0))
            # adjust the column's width to the header string
            self.tree.column(col,
                             width=tkFont.Font().measure(col.title()))

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


def sortby(tree, col, descending):
    """sort tree contents when a column header is clicked on"""
    # grab values to sort
    data = [(tree.set(child, col), child) \
            for child in tree.get_children('')]
    # if the data to be sorted is numeric change to float
    # data =  change_numeric(data)
    # now sort the data in place
    data.sort(reverse=descending)
    for ix, item in enumerate(data):
        tree.move(item[1], '', ix)
    # switch the heading so it will sort in the opposite direction
    tree.heading(col, command=lambda col=col: sortby(tree, col, \
                                                     int(not descending)))


def main():
    app = AppIU()
    app.root.mainloop()
    return 0


if __name__ == "__main__":
    main()
