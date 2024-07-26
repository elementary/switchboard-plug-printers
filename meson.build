project(
    'io.elementary.settings.printers',
    'vala', 'c',
    version: '8.0.0'
)

gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language:'c'
)

subdir('data')
subdir('src')
subdir('po')
