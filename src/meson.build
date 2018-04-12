plug_files = files(
    'PrinterPage.vala',
    'PrinterList.vala',
    'Plug.vala',
    'CUPSPkHelper.vala',
    'CUPSNotifier.vala',
    'Objects/Printer.vala',
    'Objects/PrinterManager.vala',
    'Objects/Job.vala',
    'Views/JobsView.vala',
    'Views/SetupView.vala',
    'Widgets/AddDialog.vala',
    'Widgets/EditableTitle.vala',
    'Widgets/InkLevel.vala',
    'Widgets/JobRow.vala',
    'Widgets/PrinterRow.vala'
)

switchboard_dep = dependency('switchboard-2.0')

cups_lib = meson.get_compiler('c').find_library('cups')
cups_vapi = meson.get_compiler('vala').find_library('cups', dirs: join_paths(meson.source_root(), 'vapi'))
cups_dep = declare_dependency(dependencies: [cups_lib, cups_vapi])

gettext_data = configuration_data()
gettext_data.set('GETTEXT_PACKAGE', gettext_name)
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
        dependency('granite'),
        dependency('gtk+-3.0'),
        meson.get_compiler('vala').find_library('posix'),
        cups_dep,
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'hardware')
)
