import os
import sys
from Foundation import NSBundle

__package__ = "meld"
__version__ = "3.19.0"

# START; these paths are clobbered on install by meld.build_helpers
DATADIR = os.path.join(sys.prefix, "share", "meld")
LOCALEDIR = os.path.join(sys.prefix, "share", "locale")
# END
UNINSTALLED = False
UNINSTALLED_SCHEMA = False
PYTHON_REQUIREMENT_TUPLE = (3, 3)

# Installed from main script
_ = lambda x: x
ngettext = lambda x, *args: x


def frozen():
    global DATADIR, LOCALEDIR, UNINSTALLED_SCHEMA

    bundle = NSBundle.mainBundle()
    resource_path =  bundle.resourcePath().fileSystemRepresentation().decode("utf-8")
    bundle_path = bundle.bundlePath().fileSystemRepresentation().decode("utf-8")
    frameworks_path = bundle.privateFrameworksPath().fileSystemRepresentation().decode("utf-8")
    executable_path = bundle.executablePath().fileSystemRepresentation().decode("utf-8")
    etc_path = os.path.join(resource_path , "etc")
    lib_path = os.path.join(resource_path , "lib")
    share_path = os.path.join(resource_path , "share")

    # Default to Adwaita GTK Theme or override with user's environment var
    gtk_theme= os.environ.get('GTK_THEME', "Adwaita")
    os.environ['GTK_THEME'] = gtk_theme

    # Main libraries environment variables
    #dyld_library_path = os.environ.get('DYLD_LIBRARY_PATH', '').split(':')
    #dyld_library_path.insert(0, lib_path)
    #dyld_library_path.insert(1, frameworks_path)
    #os.environ['DYLD_LIBRARY_PATH'] = ':'.join(dyld_library_path)
    #print "DYLD_LIBRARY_PATH %s" % os.environ.get('DYLD_LIBRARY_PATH', '')

    # Glib and GI environment variables
    os.environ['GSETTINGS_SCHEMA_DIR'] = os.path.join(
                                share_path, "glib-2.0")
    os.environ['GI_TYPELIB_PATH'] = os.path.join(
                                lib_path, "girepository-1.0")

    # Avoid GTK warnings unless user specifies otherwise
    debug_gtk = os.environ.get('G_ENABLE_DIAGNOSTIC', "0")
    os.environ['G_ENABLE_DIAGNOSTIC'] = debug_gtk

    # GTK environment variables
    os.environ['GTK_DATA_PREFIX'] = resource_path
    os.environ['GTK_EXE_PREFIX'] = resource_path
    os.environ['GTK_PATH'] = resource_path

    # XDG environment variables
    os.environ['XDG_CONFIG_DIRS'] = os.path.join(etc_path, "xdg")
    os.environ['XDG_DATA_DIRS'] = ":".join((share_path,
                                        os.path.join(share_path, "meld")))

    # Pango environment variables
    os.environ['PANGO_RC_FILE'] = os.path.join(etc_path, "pango", "pangorc")
    os.environ['PANGO_SYSCONFDIR'] = etc_path
    os.environ['PANGO_LIBDIR'] = lib_path

    # Gdk environment variables
    os.environ['GDK_PIXBUF_MODULEDIR'] = os.path.join(
                            lib_path, "gdk-pixbuf-2.0", "2.10.0", "loaders")
    #os.environ['GDK_RENDERING'] = "image"

    # Python environment variables
    os.environ['PYTHONHOME'] = resource_path
    original_python_path = os.environ.get('PYTHONPATH', "")
    python_path = ":".join((lib_path,
                    os.path.join(lib_path, "python", "lib-dynload"),
                    os.path.join(lib_path, "python"),
                    original_python_path))
    os.environ['PYTHONPATH'] = python_path

    # meld specific
    DATADIR = os.path.join(share_path, "meld")
    LOCALEDIR = os.path.join(share_path, "mo")
    UNINSTALLED_SCHEMA = True

def uninstalled():
    # Always use frozen when building...
    return frozen()

def ui_file(filename):
    return os.path.join(DATADIR, "ui", filename)

def is_darwin():
    return sys.platform == "darwin"
