
import os
import sys
from pathlib import Path
try:
    from Foundation import NSBundle
except:
    pass

__package__ = "meld"
__version__ = "3.21.0.osx4"

APPLICATION_NAME = 'Meld'
APPLICATION_ID = 'org.gnome.Meld'
SETTINGS_SCHEMA_ID = 'org.gnome.meld'
RESOURCE_BASE = '/org/gnome/meld'

# START; these paths are clobbered on install by meld.build_helpers
DATADIR = Path(sys.prefix) / "share" / "meld"
LOCALEDIR = Path(sys.prefix) / "share" / "locale"
# END

CONFIGURED = '@configured@'
PROFILE = 'macOS'

if CONFIGURED == 'True':
    APPLICATION_ID = '@application_id@'
    DATADIR = '@pkgdatadir@'
    LOCALEDIR = '@localedir@'
    PROFILE = '@profile@'

# Flag enabling some workarounds if data dir isn't installed in standard prefix
DATADIR_IS_UNINSTALLED = False
PYTHON_REQUIREMENT_TUPLE = (3, 6)


# Installed from main script
def no_translation(gettext_string: str) -> str:
    return gettext_string


_ = no_translation
ngettext = no_translation


def frozen():
    global DATADIR, LOCALEDIR, DATADIR_IS_UNINSTALLED

    bundle = NSBundle.mainBundle()
    resource_path =  bundle.resourcePath().fileSystemRepresentation().decode("utf-8")
    #bundle_path = bundle.bundlePath().fileSystemRepresentation().decode("utf-8")
    #frameworks_path = bundle.privateFrameworksPath().fileSystemRepresentation().decode("utf-8")
    #executable_path = bundle.executablePath().fileSystemRepresentation().decode("utf-8")
    etc_path = os.path.join(resource_path, "etc")
    lib_path = os.path.join(resource_path, "lib")
    share_path = os.path.join(resource_path , "share")

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
    os.environ['XDG_DATA_DIRS'] = ":".join((share_path, os.path.join(share_path, "meld")))
    os.environ['XDG_CONFIG_HOME'] = etc_path
    home_dir = os.path.expanduser('~')
    if home_dir is not None:
        cache_dir = os.path.join(home_dir, 'Library', 'Caches', 'org.gnome.meld')
        try:
            os.makedirs(cache_dir, mode=0o755, exist_ok=True)
            os.environ['XDG_CACHE_HOME'] = cache_dir
        except EnvironmentError:
            pass
        if os.path.isdir(cache_dir):
            os.environ['XDG_CACHE_HOME'] = cache_dir

    # Pango environment variables
    os.environ['PANGO_RC_FILE'] = os.path.join(etc_path, "pango", "pangorc")
    os.environ['PANGO_SYSCONFDIR'] = etc_path
    os.environ['PANGO_LIBDIR'] = lib_path

    # Gdk environment variables
    os.environ['GDK_PIXBUF_MODULEDIR'] = os.path.join(lib_path, "gdk-pixbuf-2.0", "2.10.0", "loaders")
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
    DATADIR_IS_UNINSTALLED = True


def uninstalled():
    global DATADIR, LOCALEDIR, DATADIR_IS_UNINSTALLED

    melddir = Path(__file__).resolve().parent.parent

    DATADIR = melddir / "data"
    LOCALEDIR = melddir / "build" / "mo"
    DATADIR_IS_UNINSTALLED = True

    resource_path = melddir / "meld" / "resources"
    os.environ['G_RESOURCE_OVERLAYS'] = f'{RESOURCE_BASE}={resource_path}'

def ui_file(filename):
    return os.path.join(DATADIR, "ui", filename)
