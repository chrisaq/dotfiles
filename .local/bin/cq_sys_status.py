import gi
gi.require_version("Gtk", "3.0")  # Use "4.0" for GTK 4 if required
from gi.repository import Gtk, Gdk, GLib

class MyWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="Tabbed GTK GUI")

        # Create a Notebook (Tab container)
        self.notebook = Gtk.Notebook()

        # Create the "System" tab content
        self.system_tab = self.create_system_tab()

        # Add tabs to the notebook
        self.notebook.append_page(self.system_tab, Gtk.Label(label="System"))
        self.notebook.append_page(Gtk.Label(label="Other Tab"), Gtk.Label(label="Other"))

        # Add the notebook to the window
        self.add(self.notebook)

        # Start the periodic clipboard update (every 1000 ms or 1 second)
        GLib.timeout_add(1000, self.update_clipboard_content)

    def create_system_tab(self):
        """Creates the content for the System tab, showing the PRIMARY and CLIPBOARD selections."""
        self.vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)

        # Create labels to display the clipboard contents
        self.primary_label = Gtk.Label(label="PRIMARY Selection: Loading...")
        self.clipboard_label = Gtk.Label(label="System Clipboard: Loading...")

        # Add the labels to the vertical box (vbox)
        self.vbox.pack_start(self.primary_label, True, True, 0)
        self.vbox.pack_start(self.clipboard_label, True, True, 0)

        return self.vbox

    def update_clipboard_content(self):
        """Fetch the current clipboard contents and update the labels."""
        # Get the contents of the PRIMARY selection
        primary_clipboard = Gtk.Clipboard.get(Gdk.SELECTION_PRIMARY)
        primary_text = primary_clipboard.wait_for_text() or "No PRIMARY selection data"
        
        # Get the contents of the CLIPBOARD
        system_clipboard = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
        clipboard_text = system_clipboard.wait_for_text() or "No CLIPBOARD data"

        # Update the labels with the new clipboard data
        self.primary_label.set_text(f"PRIMARY Selection: {primary_text}")
        self.clipboard_label.set_text(f"System Clipboard: {clipboard_text}")

        # Return True to keep the timeout active (so it continues to be called)
        return True


# Initialize GTK Application
win = MyWindow()
win.connect("destroy", Gtk.main_quit)  # Close the window when clicked on close
win.show_all()  # Show the window and all its contents

# Start the GTK main loop
Gtk.main()

