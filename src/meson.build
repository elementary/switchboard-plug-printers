plug_files = files(
    'PrinterPage.vala',
    'PrinterList.vala',
    'Plug.vala',
    'CUPSPkHelper.vala',
    'CUPSNotifier.vala',
    'Dialogs/AddDialog.vala',
    'Dialogs/ClearQueueDialog.vala',
    'Dialogs/RemoveDialog.vala',
    'Objects/DeviceDriver.vala',
    'Objects/Printer.vala',
    'Objects/PrinterManager.vala',
    'Objects/TempDevice.vala',
    'Objects/Job.vala',
    'Views/JobsView.vala',
    'Views/SetupView.vala',
    'Views/SuppliesView.vala',
    'Widgets/InkLevel.vala',
    'Widgets/JobRow.vala',
    'Widgets/PrinterRow.vala'
)

switchboard_dep = dependency('switchboard-3')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

cups_lib = meson.get_compiler('c').find_library('cups')
cups_vapi = meson.get_compiler('vala').find_library('cups', dirs: join_paths(meson.source_root(), 'vapi'))
cups_dep = declare_dependency(dependencies: [cups_lib, cups_vapi])

gettext_data = configuration_data()
gettext_data.set('GETTEXT_PACKAGE', gettext_name)
gettext_data.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
gettext_declaration = configure_file(
    configuration: gettext_data,
    input: 'config.vala.in',
    output: '@BASENAME@'
)

shared_module(
    meson.project_name(),
    plug_files,
    gettext_declaration,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7'),
        dependency('gtk4'),
        meson.get_compiler('vala').find_library('posix'),
        cups_dep,
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'hardware')
)
