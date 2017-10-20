// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Pantheon Developers (https://launchpad.net/switchboard-plug-printers)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.JobsView : Gtk.Frame {
    private Printer printer;
    private Gtk.ListBox list_box;
    private Gtk.Stack stack;

    public JobsView (Printer printer) {
        this.printer = printer;

        var job_grid = new Gtk.Grid ();
        job_grid.orientation = Gtk.Orientation.VERTICAL;

        list_box = new Gtk.ListBox ();
        list_box.set_selection_mode (Gtk.SelectionMode.SINGLE);
        list_box.set_sort_func (compare);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (list_box);
        scrolled.show_all ();

        var toolbar = new Gtk.Toolbar ();
        toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        toolbar.get_style_context ().add_class ("inline-toolbar");
        var start_pause_button = new Gtk.ToolButton (null, null);
        start_pause_button.icon_name = "media-playback-pause-symbolic";
        start_pause_button.sensitive = false;
        var stop_button = new Gtk.ToolButton (null, null);
        stop_button.icon_name = "media-playback-stop-symbolic";
        stop_button.sensitive = false;
        var expander = new Gtk.ToolItem ();
        expander.set_expand (true);
        expander.visible_vertical = false;

        var show_all_button = new Gtk.ToggleToolButton ();
        show_all_button.label = _("Show completed jobs");
        show_all_button.toggled.connect (() => {
            toggle_finished (show_all_button);
        });

        toolbar.add (start_pause_button);
        toolbar.add (stop_button);
        toolbar.add (expander);
        toolbar.add (show_all_button);

        var alert = new Granite.Widgets.AlertView (_("No jobs"), _("There are no jobs on the queue"), "document");
        alert.show_all ();

        stack = new Gtk.Stack ();
        stack.add_named (scrolled, "jobs");
        stack.add_named (alert, "no-jobs");
        stack.set_visible_child_name ("no-jobs");

        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var job in jobs) {
            switch (job.cjob.state) {
                case CUPS.IPP.JobState.CANCELED:
                case CUPS.IPP.JobState.ABORTED:
                case CUPS.IPP.JobState.COMPLETED:
                    continue;
                default:
                    add_job (job);
                    stack.set_visible_child_name ("jobs");
                    continue;
            }
        }

        list_box.row_selected.connect (() => {
            JobRow job_row = list_box.get_selected_row () as JobRow;

            if (job_row != null) {
                var job = job_row.job;

                if (job.get_hold_until () == "no-hold") {
                    start_pause_button.icon_name = "media-playback-pause-symbolic";
                } else {
                    start_pause_button.icon_name = "media-playback-start-symbolic";
                }

                switch (job.cjob.state) {
                    case CUPS.IPP.JobState.PENDING:
                    case CUPS.IPP.JobState.PROCESSING:
                    case CUPS.IPP.JobState.HELD:
                        start_pause_button.sensitive = true;
                        stop_button.sensitive = true;
                        break;
                    default:
                        start_pause_button.icon_name = "media-playback-pause-symbolic";
                        start_pause_button.sensitive = false;
                        stop_button.sensitive = false;
                        break;
                }
            } else {
                start_pause_button.icon_name = "media-playback-pause-symbolic";
                start_pause_button.sensitive = false;
                stop_button.sensitive = false;
            }
        });

        start_pause_button.clicked.connect (() => {
            JobRow job_row = list_box.get_selected_row () as JobRow;

            if (job_row != null) {
                var job = job_row.job;

                unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
                if (job.get_hold_until () == "no-hold") {
                    try {
                        pk_helper.job_set_hold_until (job.cjob.id, "indefinite");
                        start_pause_button.icon_name = "media-playback-start-symbolic";
                    } catch (Error e) {
                        critical (e.message);
                    }
                } else {
                    try {
                        pk_helper.job_set_hold_until (job.cjob.id, "no-hold");
                        start_pause_button.icon_name = "media-playback-pause-symbolic";
                    } catch (Error e) {
                        critical (e.message);
                    }
                }
            }
        });

        stop_button.clicked.connect (() => {
            JobRow job_row = list_box.get_selected_row () as JobRow;

            if (job_row != null) {
                var job = job_row.job;

                unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
                try {
                    pk_helper.job_cancel_purge (job.cjob.id, false);
                    start_pause_button.sensitive = false;
                    stop_button.sensitive = false;
                } catch (Error e) {
                    critical (e.message);
                }
            }
        });

        job_grid.add (stack);
        job_grid.add (toolbar);
        add (job_grid);

        unowned Cups.Notifier notifier  = Cups.Notifier.get_default ();
        notifier.job_created.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
            if (printer.dest.name != name) {
                return;
            }

            var jobs_ = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs_) {
                if (job.cjob.id == job_id) {
                    add_job (job);
                    break;
                }
            }
        });
    }

    private void add_job (Job job) {
        list_box.add (new JobRow (printer, job));
        list_box.invalidate_sort ();
    }

    private void toggle_finished (Gtk.ToggleToolButton button) {
        if (button.active == true) {
            button.label = _("Hide completed jobs");

            var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs) {
                switch (job.cjob.state) {
                    case CUPS.IPP.JobState.CANCELED:
                    case CUPS.IPP.JobState.ABORTED:
                    case CUPS.IPP.JobState.COMPLETED:
                        add_job (job);
                        continue;
                    default:
                        continue;
                }
            }
        } else {
            button.label = _("Show completed jobs");

            foreach (Gtk.Widget widget in list_box.get_children ()) {
                JobRow job_row = widget as JobRow;

                if (job_row == null) {
                    continue;
                }

                switch (job_row.job.cjob.state) {
                    case CUPS.IPP.JobState.CANCELED:
                    case CUPS.IPP.JobState.ABORTED:
                    case CUPS.IPP.JobState.COMPLETED:
                        list_box.remove (job_row);
                        continue;
                    default:
                        continue;
                }
            }
        }

        if (list_box.get_children ().length () > 0) {
            stack.set_visible_child_name ("jobs");
        } else {
            stack.set_visible_child_name ("no-jobs");
        }
    }

    static int compare (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
        var timea = (((JobRow)a).job.get_used_time ());
        var timeb = (((JobRow)b).job.get_used_time ());
        return timeb.compare (timea);
    }
}

public class Printers.JobRow : Gtk.ListBoxRow {
    public Job job { get; private set; }
    private Printer printer;

    private Gtk.Grid grid;

    public JobRow (Printer printer, Job job) {
        this.printer = printer;
        this.job = job;

        grid = new Gtk.Grid ();
        grid.tooltip_text = job.translated_job_state ();
        grid.column_spacing = 6;
        grid.row_spacing = 6;
        grid.margin = 6;

        Gtk.Image icon = new Gtk.Image.from_gicon (job.get_file_icon (), Gtk.IconSize.MENU);
        grid.attach (icon, 0, 0);

        Gtk.Label title = new Gtk.Label (job.cjob.title);
        title.hexpand = true;
        title.halign = Gtk.Align.START;
        title.ellipsize = Pango.EllipsizeMode.END;
        grid.attach (title, 1, 0);

        var date_time = job.get_used_time ();
        string date_string = date_time.format ("%F %T");
        Gtk.Label date = new Gtk.Label (date_string);
        grid.attach (date, 2, 0);

        Gtk.Widget state;
        if (job.state_icon () != null) {
            state = new Gtk.Image.from_gicon (job.state_icon (), Gtk.IconSize.MENU);
        } else {
            state = new Gtk.Spinner ();
            ((Gtk.Spinner)state).active = true;
            ((Gtk.Spinner)state).start ();
        }
        grid.attach (state, 3, 0);

        job.state_changed.connect (update_state);
        job.completed.connect (update_state);
        job.stopped.connect (update_state);

        add (grid);
        show_all ();
    }

    public void update_state () {
        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var _job in jobs) {
            if (_job.cjob.id == job.cjob.id) {
                job = _job;
                break;
            }
        }

        Gtk.Widget state;
        if (job.state_icon () != null) {
            state = new Gtk.Image.from_gicon (job.state_icon (), Gtk.IconSize.MENU);
        } else {
            state = new Gtk.Spinner ();
            ((Gtk.Spinner)state).active = true;
            ((Gtk.Spinner)state).start ();
        }
        grid.remove_column (3);
        grid.attach (state, 3, 0);
        show_all ();

        grid.tooltip_text = job.translated_job_state ();
    }
}
