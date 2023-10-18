/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2015-2023 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.JobsView : Gtk.Frame {
    public Printer printer { get; construct; }

    private Gtk.ListBox list_box;
    private Gtk.Button clear_button;

    public JobsView (Printer printer) {
        Object (printer: printer);
    }

    construct {
        var alert = new Granite.Widgets.AlertView (_("Print Queue Is Empty"), _("There are no pending jobs in the queue."), "");
        alert.show_all ();

        list_box = new Gtk.ListBox () {
            selection_mode = SINGLE
        };
        list_box.set_placeholder (alert);
        list_box.set_header_func ((Gtk.ListBoxUpdateHeaderFunc) update_header);
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) compare);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = list_box,
            hexpand = true,
            vexpand = true
        };

        var clear_button_box = new Gtk.Box (HORIZONTAL, 0);
        clear_button_box.add (new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", BUTTON));
        clear_button_box.add (new Gtk.Label (_("Clear All")));

        clear_button = new Gtk.Button () {
            child = clear_button_box,
            sensitive = list_box.get_children ().length () > 0
        };
        clear_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        actionbar.pack_start (clear_button);

        var box = new Gtk.Box (VERTICAL, 0);
        box.add (scrolled);
        box.add (actionbar);

        child = box;

        refresh_job_list ();

        unowned Cups.Notifier notifier = Cups.Notifier.get_default ();
        notifier.job_created.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
            if (printer.dest.name != name) {
                return;
            }

            var jobs_ = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs_) {
                if (job.uid == job_id) {
                    list_box.add (new JobRow (printer, job));
                    break;
                }
            }

            clear_button.sensitive = list_box.get_children ().length () > 0;
        });

        clear_button.clicked.connect (() => clear_queue ());
    }

    // Sort all ongoing jobs first, otherwise sort in descending order of displayed time (null last)
    static int compare (JobRow a, JobRow b) {
        if (a.job.is_ongoing && !b.job.is_ongoing) {
            return -1;
        } else if (!a.job.is_ongoing && b.job.is_ongoing) {
            return 1;
        } else {
            var timea = (((JobRow)a).job.get_display_time ());
            var timeb = (((JobRow)b).job.get_display_time ());
            if (timea == null) {
                if (timeb == null) {
                    return 0;
                } else {
                    return 1;
                }
            } else if (timeb == null) {
                return -1;
            } else {
                return timeb.compare (timea);
            }
        }
    }

    [CCode (instance_pos = -1)]
    private void update_header (JobRow row1, JobRow? row2) {
        if (!row1.job.is_ongoing && (row2 == null || row2.job.is_ongoing)) {
            var label = new Gtk.Label (_("Completed Jobs")) {
                xalign = 0,
                margin_top = 3,
                margin_end = 3,
                margin_bottom = 3,
                margin_start = 3
            };
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            row1.set_header (label);
        } else {
            row1.set_header (null);
        }
    }

    public void clear_queue () {
        var dialog = new ClearQueueDialog (printer) {
            transient_for = (Gtk.Window) get_toplevel ()
        };
        dialog.response.connect ((response_id) => {
            dialog.destroy ();

            if (response_id == Gtk.ResponseType.OK) {
                list_box.@foreach ((row) => {
                    var job = ((JobRow)row).job;
                    job.pause (); // Purging pending/in_progress jobs does not always remove canceled job
                    job.purge ();
                });

                refresh_job_list ();
            }
        });

        dialog.present ();
    }

    private void refresh_job_list () {
        list_box.@foreach ((row) => {
            list_box.remove (row);
        });

        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var job in jobs) {
            list_box.add (new JobRow (printer, job));
        }

        clear_button.sensitive = list_box.get_children ().length () > 0;
    }
}
